from __future__ import annotations

import copy
from dataclasses import dataclass
import os
from typing import Protocol, Optional, Any

from kubernetes import client as kubeclient, config as kubeconfig
import requests
import urllib3


request_timeout: int = 60
request_verify_certificate: bool = False

if not request_verify_certificate:
    urllib3.disable_warnings()


@dataclass
class OAuth2Token:
    access: str
    refresh: str


@dataclass
class Realm:
    name: str
    display_name: Optional[str]
    login_theme: Optional[str]

    def to_keycloak_json(self) -> dict[str, Any]:
        json: dict[str, Any] = {
            "realm": self.name,
            "enabled": True,
            "displayName": (
                self.display_name if self.display_name is not None else self.name
            ),
            "displayNameHtml": (
                self.display_name if self.display_name is not None else self.name
            ),
        }
        if self.login_theme is not None:
            json["loginTheme"] = self.login_theme
        return json


@dataclass
class NamespacedName:
    name: str
    namespace: str


@dataclass
class ClientRole:
    name: str
    client: Client


@dataclass
class ClientScope:
    name: str
    roles: list[ClientRole]

    def to_keycloak_json(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "description": "",
            "protocol": "openid-connect",
            "attributes": {
                "include.in.token.scope": "true",
                "display.on.consent.screen": "true",
            },
        }




class Client(Protocol):
    id: str
    name: str
    scopes: list[ClientScope]
    kube_secret_name: Optional[NamespacedName]

    uuid: Optional[str] = None
    service_account_user_id: Optional[str] = None

    roles: list[ClientRole] = list()

    def set_secret(self, secret: str) -> None: ...

    def to_keycloak_json(self) -> dict[str, Any]: ...

    def to_kubernetes_secret_data(self) -> dict[str, str]: ...


class Oauth2ProxyClient:
    id: str
    name: str
    scopes: list[ClientScope] = list()
    redirect: str
    logout: str
    secret: str
    kube_secret_name: NamespacedName
    cookie_secret: str

    uuid: Optional[str] = None
    service_account_user_id: Optional[str] = None

    roles: list[ClientRole] = list()

    def set_secret(self, secret: str) -> None:
        self.secret = secret

    def to_keycloak_json(self) -> dict[str, Any]:
        json = {
            "protocol": "openid-connect",
            "clientId": self.id,
            "name": self.name,
            "enabled": True,
            "publicClient": False,
            "standardFlowEnabled": True,
            "implicitFlowEnabled": False,
            "directAccessGrantsEnabled": False,
            "serviceAccountsEnabled": False,
            "authorizationServicesEnabled": False,
            "optionalClientScopes": [scope.name for scope in self.scopes]
        }

        if self.redirect:
            json["redirectUris"] = [self.redirect]
        if self.logout:
            json["frontchannelLogout"] = True
            json["attributes"] = {
                "frontchannel.logout.url": f"{self.logout}",
            }

        return json

    def to_kubernetes_secret_data(self) -> dict[str, str]:
        return {
            "client-id": self.id,
            "client-secret": self.secret,
            "cookie-secret": self.cookie_secret,
        }


class InternalClient:
    id: str
    name: str
    scopes: list[ClientScope] = list()
    secret: str
    kube_secret_name: NamespacedName

    uuid: Optional[str] = None
    service_account_user_id: Optional[str] = None

    roles: list[ClientRole] = list()

    def set_secret(self, secret: str) -> None:
        self.secret = secret

    def to_keycloak_json(self) -> dict[str, Any]:
        json = {
            "protocol": "openid-connect",
            "clientId": self.id,
            "name": self.name,
            "enabled": True,
            "publicClient": False,
            "standardFlowEnabled": False,
            "implicitFlowEnabled": False,
            "directAccessGrantsEnabled": False,
            "serviceAccountsEnabled": True,
            "authorizationServicesEnabled": False,
            "optionalClientScopes": [scope.name for scope in self.scopes]
        }

        return json

    def to_kubernetes_secret_data(self) -> dict[str, str]:
        return {
            "client-id": self.id,
            "client-secret": self.secret,
        }


class ExternalClient:
    id: str
    name: str
    scopes: list[ClientScope] = list()
    secret: str
    kube_secret_name: None = None

    uuid: Optional[str] = None
    service_account_user_id: Optional[str] = None

    roles: list[ClientRole] = list()

    def set_secret(self, secret: str) -> None:
        self.secret = secret

    def to_keycloak_json(self) -> dict[str, Any]:
        json = {
            "protocol": "openid-connect",
            "clientId": self.id,
            "name": self.name,
            "enabled": True,
            "publicClient": False,
            "standardFlowEnabled": False,
            "implicitFlowEnabled": False,
            "directAccessGrantsEnabled": False,
            "serviceAccountsEnabled": True,
            "authorizationServicesEnabled": False,
            "optionalClientScopes": [scope.name for scope in self.scopes]
        }

        return json

    def to_kubernetes_secret_data(self) -> dict[str, str]:
        return {}


@dataclass
class User:
    username: str
    email: str
    password: str

    id: Optional[str] = None

    def to_keycloak_json(self) -> dict[str, Any]:
        return {
            "username": self.username,
            "enabled": True,
            "email": self.email,
            "emailVerified": True,
            "credentials": [
                {
                    "type": "password",
                    "value": self.password,
                    "temporary": False,
                }
            ],
        }


class KeycloakConfig:
    base_url: str
    token: OAuth2Token
    realm: Realm


def main() -> None:
    drax_endpoint = os.environ.get("DRAX_ENDPOINT")

    kubernetes_namespace = os.environ.get("KUBERNETES_NAMESPACE", "default")

    config: KeycloakConfig = KeycloakConfig()
    config.base_url = os.environ.get("KEYCLOAK_URL", default="")
    config.realm = Realm(
        name=os.environ.get("KEYCLOAK_REALM_NAME", default="master"),
        display_name=os.environ.get("KEYCLOAK_REALM_DISPLAY_NAME"),
        login_theme=os.environ.get("KEYCLOAK_REALM_LOGIN_THEME"),
    )

    master_config: KeycloakConfig = copy.copy(config)
    master_realm: Realm = Realm(name="master", display_name=None, login_theme=None)
    master_config.realm = master_realm

    tmp_user = User(
        username=os.environ.get("KEYCLOAK_TMP_USERNAME", default=""),
        email="",
        password=os.environ.get("KEYCLOAK_TMP_PASSWORD", default=""),
    )

    superadmin = User(
        username=os.environ.get("KEYCLOAK_SUPERADMIN_USERNAME", default="superadmin"),
        email=os.environ.get("KEYCLOAK_SUPERADMIN_EMAIL", default=""),
        password=os.environ.get("KEYCLOAK_SUPERADMIN_PASSWORD", default=""),
    )
    admin = User(
        username=os.environ.get("KEYCLOAK_ADMIN_USERNAME", default="admin"),
        email=os.environ.get("KEYCLOAK_ADMIN_EMAIL", default=""),
        password=os.environ.get("KEYCLOAK_ADMIN_PASSWORD", default=""),
    )

    realm_management_client = ExternalClient()
    realm_management_client.id = "realm-management"

    realm_management_view_clients_role = ClientRole(
        client=realm_management_client, name="view-clients"
    )

    client_scopes: list[ClientScope] = list()

    read_clients_client_scope = ClientScope(
        name="read-clients", roles=[realm_management_view_clients_role]
    )
    client_scopes.append(read_clients_client_scope)

    clients: list[Client] = list()

    oauth2_proxy_client = Oauth2ProxyClient()
    oauth2_proxy_client.id = os.environ.get(
        "OAUTH2_PROXY_CLIENT_ID", default="oauth2-proxy"
    )
    oauth2_proxy_client.name = "OAuth2 Proxy"
    oauth2_proxy_client.redirect = "/oauth2/callback"
    oauth2_proxy_client.logout = f"https://{drax_endpoint}/oauth2/sign_out"
    oauth2_proxy_client.kube_secret_name = NamespacedName(
        os.environ.get("OAUTH2_PROXY_SECRET_NAME", default=""),
        kubernetes_namespace,
    )
    oauth2_proxy_client.cookie_secret = os.environ.get(
        "OAUTH2_PROXY_COOKIE_SECRET", default=""
    )
    clients.append(oauth2_proxy_client)

    dashboard_client = InternalClient()
    dashboard_client.id = os.environ.get("DASHBOARD_CLIENT_ID", default="dashboard")
    dashboard_client.name = "Dashboard"
    dashboard_client.kube_secret_name = NamespacedName(
        os.environ.get("DASHBOARD_SECRET_NAME", default=""),
        kubernetes_namespace,
    )
    dashboard_client.scopes.append(read_clients_client_scope)
    dashboard_client.roles.append(realm_management_view_clients_role)
    clients.append(dashboard_client)

    external_client = ExternalClient()
    external_client.id = os.environ.get(
        "EXTERNAL_CLIENT_CLIENT_ID", default="external-client"
    )
    external_client.name = "External Client"
    clients.append(external_client)

    try:
        master_config.token = sign_in(master_config, tmp_user)
        create_or_update_user(master_config, superadmin)
        add_realm_role(master_config, get_user_id(master_config, superadmin), "admin")
        delete_user(master_config, tmp_user)
    except requests.HTTPError as err:
        if 500 <= err.response.status_code < 600:
            raise err
        else:
            print("caught http error: ", err)

    master_config.token = sign_in(master_config, superadmin)
    config.token = master_config.token

    create_or_update_user(master_config, superadmin)

    create_or_update_realm(config)
    update_realm_user_profile(config)
    print("realms:", list_realms(config))

    # get the superadmin id again in the drax realm from now on
    superadmin.id = None

    create_or_update_user(config, superadmin)
    create_or_update_user(config, admin)
    print("users:", list_users(config))

    for client_scope in client_scopes:
        create_or_update_client_scope(config, client_scope)
    print("client scopes:", list_client_scopes(config))

    init_kube_client()
    for client in clients:
        create_or_update_client(config, client)
        client.set_secret(get_client_secret(config, client))
        add_client_secret_to_kubernetes_secret(client)
    print("clients:", list_clients(config))


def sign_in(config: KeycloakConfig, user: User) -> OAuth2Token:
    response = requests.post(
        f"{config.base_url}/realms/{config.realm.name}/protocol/openid-connect/token",
        data={
            "client_id": "admin-cli",
            "username": user.username,
            "password": user.password,
            "grant_type": "password",
        },
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    print(f"signed in as user {user.username}")

    data = response.json()
    access_token = data["access_token"]
    refresh_token = data["refresh_token"]

    return OAuth2Token(access_token, refresh_token)


def auth_headers(config: KeycloakConfig) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {config.token.access}",
    }


def create_or_update_realm(config: KeycloakConfig) -> None:
    if config.realm.name not in list_realms(config):
        create_realm(config)
    else:
        update_realm(config)


def list_realms(config: KeycloakConfig) -> list[str]:
    response = requests.get(
        f"{config.base_url}/admin/realms",
        headers=auth_headers(config),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    realms = [r["realm"] for r in response.json()]
    return realms


def create_realm(config: KeycloakConfig) -> None:
    response = requests.post(
        f"{config.base_url}/admin/realms",
        headers=auth_headers(config),
        json=config.realm.to_keycloak_json(),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    print(f"created realm {config.realm.name}")


def update_realm(config: KeycloakConfig) -> None:
    response = requests.put(
        f"{config.base_url}/admin/realms/{config.realm.name}",
        headers=auth_headers(config),
        json=config.realm.to_keycloak_json(),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    print(f"updated realm {config.realm.name}")


def update_realm_user_profile(config: KeycloakConfig) -> None:
    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/users/profile",
        headers=auth_headers(config),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()

    user_profile = response.json()
    user_profile = loosen_user_profile_requirements(user_profile)

    response = requests.put(
        f"{config.base_url}/admin/realms/{config.realm.name}/users/profile",
        headers=auth_headers(config),
        json=user_profile,
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    print(f"updated realm {config.realm.name} user profile")


def loosen_user_profile_requirements(user_profile: dict[str, Any]) -> dict[str, Any]:
    for attribute in user_profile["attributes"]:
        if attribute["name"] not in ["email"]:
            attribute.pop("required", None)

    return user_profile


def create_or_update_user(config: KeycloakConfig, user: User) -> None:
    if user.username not in list_users(config):
        create_user(config, user)
    else:
        update_user(config, user)


def list_users(config: KeycloakConfig) -> list[str]:
    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/users",
        headers=auth_headers(config),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    users = [r["username"] for r in response.json()]
    return users


def create_user(config: KeycloakConfig, user: User) -> None:
    response = requests.post(
        f"{config.base_url}/admin/realms/{config.realm.name}/users",
        headers=auth_headers(config),
        json=user.to_keycloak_json(),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    print(f"created user {user.username}")


def update_user(config: KeycloakConfig, user: User) -> None:
    user_id = get_user_id(config, user)

    response = requests.put(
        f"{config.base_url}/admin/realms/{config.realm.name}/users/{user_id}",
        headers=auth_headers(config),
        json=user.to_keycloak_json(),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    print(f"updated user {user.username}")


def delete_user(config: KeycloakConfig, user: User) -> None:
    user_id = get_user_id(config, user)

    response = requests.delete(
        f"{config.base_url}/admin/realms/{config.realm.name}/users/{user_id}",
        headers=auth_headers(config),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    print(f"deleted user {user.username}")


def get_user_id(config: KeycloakConfig, user: User) -> str:
    if user.id is None:
        response = requests.get(
            f"{config.base_url}/admin/realms/{config.realm.name}/users",
            headers=auth_headers(config),
            params={
                "exact": True,
                "username": f"{user.username}",
            },
            timeout=request_timeout,
            verify=request_verify_certificate,
        )
        response.raise_for_status()

        users = [r["id"] for r in response.json()]
        if len(users) != 1:
            raise RuntimeError(
                f"found {len(users)} users with username '{user.username}' (instead of 1)"
            )

        user.id = users[0]
        print(f"user {user.username} has uuid {user.id}")

    return user.id


def create_or_update_client(config: KeycloakConfig, client: Client) -> None:
    if client.id not in list_clients(config):
        create_client(config, client)
    else:
        update_client(config, client)

    for role in client.roles:
        add_client_role(config, get_client_service_account_user_id(config, client), role)



def list_clients(config: KeycloakConfig) -> list[str]:
    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/clients",
        headers=auth_headers(config),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    clients = [r["clientId"] for r in response.json()]
    return clients


def create_client(config: KeycloakConfig, client: Client) -> None:
    resp = requests.post(
        f"{config.base_url}/admin/realms/{config.realm.name}/clients",
        headers=auth_headers(config),
        json=client.to_keycloak_json(),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    resp.raise_for_status()
    print(f"created client {client.id}")


def update_client(config: KeycloakConfig, client: Client) -> None:
    client_id = get_client_id(config, client)

    resp = requests.put(
        f"{config.base_url}/admin/realms/{config.realm.name}/clients/{client_id}",
        headers=auth_headers(config),
        json=client.to_keycloak_json(),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    resp.raise_for_status()
    print(f"updated client {client.id}")


def get_client_secret(config: KeycloakConfig, client: Client) -> str:
    client_id = get_client_id(config, client)

    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/clients/{client_id}/client-secret",
        headers=auth_headers(config),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()

    client_secret = response.json()["value"]
    if client_secret is None:
        raise RuntimeError(
            f"got no client secret value for id '{client.id}'",
        )
    return client_secret


def get_client_id(config: KeycloakConfig, client: Client) -> str:
    if client.uuid is None:
        response = requests.get(
            f"{config.base_url}/admin/realms/{config.realm.name}/clients",
            headers=auth_headers(config),
            params={
                "search": False,
                "clientId": f"{client.id}",
            },
            timeout=request_timeout,
            verify=request_verify_certificate,
        )
        response.raise_for_status()

        clients = [r["id"] for r in response.json()]
        if len(clients) != 1:
            raise RuntimeError(
                f"found {len(clients)} clients with id '{client.id}' (instead of 1)",
            )

        client.uuid = clients[0]
        print(f"client {client.id} has uuid {client.uuid}")

    return client.uuid


def get_client_role_id(config: KeycloakConfig, client: Client, role_name: str) -> str:
    client_id = get_client_id(config, client)

    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/clients/{client_id}/roles",
        headers=auth_headers(config),
        params={
            "search": role_name,
        },
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()

    roles = [r["id"] for r in response.json()]
    if len(roles) != 1:
        raise RuntimeError(
            f"found {len(roles)} roles associated with client '{client.id}' with name '{role_name}' (instead of 1)"
        )

    return roles[0]


def get_client_service_account_user_id(config: KeycloakConfig, client: Client) -> str:
    if client.service_account_user_id is None:
        client_id = get_client_id(config, client)

        response = requests.get(
            f"{config.base_url}/admin/realms/{config.realm.name}/clients/{client_id}/service-account-user",
            headers=auth_headers(config),
            timeout=request_timeout,
            verify=request_verify_certificate,
        )
        response.raise_for_status()

        client.service_account_user_id = response.json()["id"]

    return client.service_account_user_id


def add_realm_role(config: KeycloakConfig, user_id: str, role: str) -> None:
    role_id = get_realm_role_id(config, role)

    response = requests.post(
        f"{config.base_url}/admin/realms/{config.realm.name}/users/{user_id}/role-mappings/realm",
        headers=auth_headers(config),
        json=[{"id": role_id, "name": role}],
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    print(f"added role {role} to user {user_id}")


def get_realm_role_id(config: KeycloakConfig, role: str) -> str:
    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/roles/{role}",
        headers=auth_headers(config),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    return response.json()["id"]


def add_client_role(config: KeycloakConfig, user_id: str, role: ClientRole) -> None:
    client_id = get_client_id(config, role.client)
    role_id = get_client_role_id(config, role.client, role.name)

    response = requests.post(
        f"{config.base_url}/admin/realms/{config.realm.name}/users/{user_id}/role-mappings/clients/{client_id}",
        headers=auth_headers(config),
        json=[{"id": role_id, "name": role.name}],
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    print(f"added role {role.name} to user {user_id}")


def create_or_update_client_scope(
    config: KeycloakConfig, client_scope: ClientScope
) -> None:
    if client_scope.name not in list_client_scopes(config):
        create_client_scope(config, client_scope)
    else:
        update_client_scope(config, client_scope)

    for role in client_scope.roles:
        add_client_scope_role(config, client_scope, role)


def list_client_scopes(config: KeycloakConfig) -> list[str]:
    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/client-scopes",
        headers=auth_headers(config),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()

    clients = [r["name"] for r in response.json()]
    return clients


def create_client_scope(config: KeycloakConfig, client_scope: ClientScope) -> None:
    response = requests.post(
        f"{config.base_url}/admin/realms/{config.realm.name}/client-scopes",
        headers=auth_headers(config),
        json=client_scope.to_keycloak_json(),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    print(f"created client {client_scope.name}")


def update_client_scope(config: KeycloakConfig, client_scope: ClientScope) -> None:
    client_scope_id = get_client_scope_id(config, client_scope)

    response = requests.put(
        f"{config.base_url}/admin/realms/{config.realm.name}/client-scopes/{client_scope_id}",
        headers=auth_headers(config),
        json=client_scope.to_keycloak_json(),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()
    print(f"updated client {client_scope.name}")


def get_client_scope_id(config: KeycloakConfig, client_scope: ClientScope) -> str:
    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/client-scopes",
        headers=auth_headers(config),
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()

    client_scopes = [r["id"] for r in response.json() if r["name"] == client_scope.name]
    if len(client_scopes) != 1:
        raise RuntimeError(
            f"found {len(client_scopes)} client scopes with name '{client_scope.name}' (instead of 1)",
        )

    return client_scopes[0]


def add_client_scope_role(
    config: KeycloakConfig, client_scope: ClientScope, role: ClientRole
) -> None:
    client_scope_id = get_client_scope_id(config, client_scope)
    client_id = get_client_id(config, role.client)
    view_clients_role_id = get_client_role_id(config, role.client, role.name)

    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/client-scopes/{client_scope_id}/scope-mappings/clients/{client_id}",
        headers=auth_headers(config),
        json={
            "id": view_clients_role_id,
        },
        timeout=request_timeout,
        verify=request_verify_certificate,
    )
    response.raise_for_status()


def init_kube_client():
    try:
        kubeconfig.load_incluster_config()
    except:
        kubeconfig.load_kube_config()


def add_client_secret_to_kubernetes_secret(client: Client) -> None:
    if client.kube_secret_name is None:
        return

    if client.kube_secret_name.name not in list_secrets(client.kube_secret_name):
        create_secret(client.kube_secret_name, client.to_kubernetes_secret_data())
    else:
        update_secret(client.kube_secret_name, client.to_kubernetes_secret_data())


def list_secrets(namespaced_name: NamespacedName) -> list[str]:
    core_v1_api = kubeclient.CoreV1Api()
    secret_list = core_v1_api.list_namespaced_secret(namespaced_name.namespace)
    return [s.metadata.name for s in secret_list.items]


def create_secret(namespaced_name: NamespacedName, string_data: dict[str, str]) -> None:
    if string_data is None:
        return

    core_v1_api = kubeclient.CoreV1Api()
    secret = kubeclient.V1Secret(
        api_version="v1",
        kind="Secret",
        metadata=kubeclient.V1ObjectMeta(name=namespaced_name.name),
        string_data=string_data,
    )
    core_v1_api.create_namespaced_secret(
        namespace=namespaced_name.namespace, body=secret
    )
    print(f"created secret {namespaced_name.namespace}/{namespaced_name.name}")


def update_secret(namespaced_name: NamespacedName, string_data: dict[str, str]) -> None:
    if string_data is None:
        return

    core_v1_api = kubeclient.CoreV1Api()
    secret = kubeclient.V1Secret(
        api_version="v1",
        kind="Secret",
        metadata=kubeclient.V1ObjectMeta(name=namespaced_name.name),
        string_data=string_data,
    )
    core_v1_api.patch_namespaced_secret(
        name=namespaced_name.name, namespace=namespaced_name.namespace, body=secret
    )
    print(f"updated secret {namespaced_name.namespace}/{namespaced_name.name}")


if __name__ == "__main__":
    main()
