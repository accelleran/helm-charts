from base64 import b64decode, b64encode
from dataclasses import dataclass
from kubernetes import client as kubeclient, config as kubeconfig
import requests
import os
import typing


@dataclass
class OAuth2Token:
    access: str
    refresh: str


@dataclass
class Realm:
    name: str
    display_name: str
    login_theme: str

    def to_keycloak_json(self) -> dict[str, any]:
        return {
            "realm": self.name,
            "enabled": True,
            "displayName": (
                self.display_name
                if not self.display_name is None
                else self.name
            ),
            "displayNameHtml": (
                self.display_name
                if not self.display_name is None
                else self.name
            ),
            "loginTheme": self.login_theme,
        }


@dataclass
class NamespacedName:
    name: str
    namespace: str


class Client(typing.Protocol):
    id: str
    name: str
    kube_secret_name: NamespacedName

    def to_keycloak_json(self) -> dict[str, any]: ...

    def to_kubernetes_secret_data(self) -> dict[str, str]: ...


class Oauth2ProxyClient:
    id: str
    name: str
    redirect: str
    logout: str
    secret: str
    kube_secret_name: str
    cookie_secret: str

    def to_keycloak_json(self) -> dict[str, any]:
        json = {
            "protocol": "openid-connect",
            "clientId": self.id,
            "name": self.name,
            "enabled": True,
            "publicClient": False,
            "standardFlowEnabled": True,
            "directAccessGrantsEnabled": False,
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


@dataclass
class User:
    username: str
    email: str
    password: str

    def to_keycloak_json(self) -> dict[str, any]:
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

    kubernetes_namespace = os.environ.get("KUBERNETES_NAMESPACE")

    config: KeycloakConfig = KeycloakConfig()
    config.base_url = os.environ.get("KEYCLOAK_URL")
    config.realm = Realm(
        name=os.environ.get("KEYCLOAK_REALM_NAME"),
        display_name=os.environ.get("KEYCLOAK_REALM_DISPLAY_NAME"),
        login_theme=os.environ.get("KEYCLOAK_REALM_LOGIN_THEME")
    )

    admin = User(
        username=os.environ.get("KEYCLOAK_ADMIN_USERNAME"),
        email=os.environ.get("KEYCLOAK_ADMIN_EMAIL"),
        password=os.environ.get("KEYCLOAK_ADMIN_PASSWORD"),
    )
    user = User(
        username=os.environ.get("KEYCLOAK_USERNAME"),
        email=os.environ.get("KEYCLOAK_EMAIL"),
        password=os.environ.get("KEYCLOAK_PASSWORD"),
    )

    clients: list[Client] = list()

    oauth2_proxy_client = Oauth2ProxyClient()
    oauth2_proxy_client.id = os.environ.get("OAUTH2_PROXY_CLIENT_ID")
    oauth2_proxy_client.name = "OAuth2 Proxy"
    oauth2_proxy_client.redirect = "/oauth2/callback"
    oauth2_proxy_client.logout = f"https://{drax_endpoint}/oauth2/sign_out"
    oauth2_proxy_client.kube_secret_name = NamespacedName(
        os.environ.get("OAUTH2_PROXY_SECRET_NAME"),
        kubernetes_namespace,
    )
    oauth2_proxy_client.cookie_secret = os.environ.get("OAUTH2_PROXY_COOKIE_SECRET")
    clients.append(oauth2_proxy_client)

    config.token = sign_in(config, admin)

    update_admin(config, admin)

    create_or_update_realm(config)
    update_realm_user_profile(config)
    print("realms:", list_realms(config))

    create_or_update_user(config, admin)
    create_or_update_user(config, user)
    print("users:", list_users(config))

    init_kube_client()
    for client in clients:
        create_or_update_client(config, client)
        client.secret = get_client_secret(config, client)
        add_client_secret_to_kubernetes_secret(client)
    print("clients:", list_clients(config))


def sign_in(config: KeycloakConfig, user: User) -> OAuth2Token:
    response = requests.post(
        f"{config.base_url}/realms/master/protocol/openid-connect/token",
        data={
            "client_id": "admin-cli",
            "username": user.username,
            "password": user.password,
            "grant_type": "password",
        },
    )
    response.raise_for_status()
    data = response.json()

    access_token = data["access_token"]
    refresh_token = data["refresh_token"]

    return OAuth2Token(access_token, refresh_token)


def auth_headers(config: KeycloakConfig) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {config.token.access}",
    }


def update_admin(config: KeycloakConfig, admin: User) -> None:
    admin_id = get_admin_id(config, admin)

    response = requests.put(
        f"{config.base_url}/admin/realms/master/users/{admin_id}",
        headers=auth_headers(config),
        json=admin.to_keycloak_json(),
    )
    response.raise_for_status()


def get_admin_id(config: KeycloakConfig, admin: User) -> str:
    response = requests.get(
        f"{config.base_url}/admin/realms/master/users",
        headers=auth_headers(config),
        params={
            "exact": True,
            "username": f"{admin.username}",
        },
    )
    response.raise_for_status()

    users = [r["id"] for r in response.json()]
    if len(users) != 1:
        raise RuntimeError(
            f"found {len(users)} users with username '{admin.username}' (instead of 1)"
        )

    return users[0]


def create_or_update_realm(config: KeycloakConfig) -> None:
    if config.realm.name not in list_realms(config):
        create_realm(config)
    else:
        update_realm(config)


def list_realms(config: KeycloakConfig) -> list[str]:
    response = requests.get(
        f"{config.base_url}/admin/realms",
        headers=auth_headers(config),
    )
    response.raise_for_status()
    realms = [r["realm"] for r in response.json()]
    return realms


def create_realm(config: KeycloakConfig) -> None:
    response = requests.post(
        f"{config.base_url}/admin/realms",
        headers=auth_headers(config),
        json=config.realm.to_keycloak_json(),
    )
    response.raise_for_status()


def update_realm(config: KeycloakConfig) -> None:
    response = requests.put(
        f"{config.base_url}/admin/realms/{config.realm.name}",
        headers=auth_headers(config),
        json=config.realm.to_keycloak_json(),
    )
    response.raise_for_status()


def update_realm_user_profile(config: KeycloakConfig) -> None:
    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/users/profile",
        headers=auth_headers(config),
    )
    response.raise_for_status()
    
    user_profile = response.json()
    user_profile = loosen_user_profile_requirements(user_profile)

    response = requests.put(
        f"{config.base_url}/admin/realms/{config.realm.name}/users/profile",
        headers=auth_headers(config),
        json=user_profile
    )
    response.raise_for_status()


def loosen_user_profile_requirements(user_profile: dict[str, any]) -> dict[str, any]:
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
    )
    response.raise_for_status()
    users = [r["username"] for r in response.json()]
    return users


def create_user(config: KeycloakConfig, user: User) -> None:
    response = requests.post(
        f"{config.base_url}/admin/realms/{config.realm.name}/users",
        headers=auth_headers(config),
        json=user.to_keycloak_json(),
    )
    response.raise_for_status()


def update_user(config: KeycloakConfig, user: User) -> None:
    user_id = get_user_id(config, user)

    response = requests.put(
        f"{config.base_url}/admin/realms/{config.realm.name}/users/{user_id}",
        headers=auth_headers(config),
        json=user.to_keycloak_json(),
    )
    response.raise_for_status()


def get_user_id(config: KeycloakConfig, user: User) -> str:
    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/users",
        headers=auth_headers(config),
        params={
            "exact": True,
            "username": f"{user.username}",
        },
    )
    response.raise_for_status()

    users = [r["id"] for r in response.json()]
    if len(users) != 1:
        raise RuntimeError(
            f"found {len(users)} users with username '{user.username}' (instead of 1)"
        )

    return users[0]


def create_or_update_client(config: KeycloakConfig, client: Client) -> None:
    if client.id not in list_clients(config):
        create_client(config, client)
    else:
        update_client(config, client)


def list_clients(config: KeycloakConfig) -> list[str]:
    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/clients",
        headers=auth_headers(config),
    )
    response.raise_for_status()
    clients = [r["clientId"] for r in response.json()]
    return clients


def create_client(config: KeycloakConfig, client: Client) -> None:
    resp = requests.post(
        f"{config.base_url}/admin/realms/{config.realm.name}/clients",
        headers=auth_headers(config),
        json=client.to_keycloak_json(),
    )
    resp.raise_for_status()


def update_client(config: KeycloakConfig, client: Client) -> None:
    client_id = get_client_id(config, client)

    resp = requests.put(
        f"{config.base_url}/admin/realms/{config.realm.name}/clients/{client_id}",
        headers=auth_headers(config),
        json=client.to_keycloak_json(),
    )
    resp.raise_for_status()


def get_client_secret(config: KeycloakConfig, client: Client) -> str:
    client_id = get_client_id(config, client)

    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/clients/{client_id}/client-secret",
        headers=auth_headers(config),
    )
    response.raise_for_status()

    client_secret = response.json()["value"]
    if client_secret is None:
        raise RuntimeError(
            f"got no client secret value for id '{client.id}'",
        )
    return client_secret


def get_client_id(config: KeycloakConfig, client: Client) -> str:
    response = requests.get(
        f"{config.base_url}/admin/realms/{config.realm.name}/clients",
        headers=auth_headers(config),
        params={
            "search": False,
            "clientId": f"{client.id}",
        },
    )
    response.raise_for_status()

    clients = [r["id"] for r in response.json()]
    if len(clients) != 1:
        raise RuntimeError(
            f"found {len(clients)} clients with id '{client.id}' (instead of 1)",
        )

    return clients[0]


def init_kube_client():
    try:
        kubeconfig.load_incluster_config()
    except:
        kubeconfig.load_kube_config()


def add_client_secret_to_kubernetes_secret(client: Client) -> None:
    if client.kube_secret_name.name not in list_secrets(client.kube_secret_name):
        create_secret(client.kube_secret_name, client.to_kubernetes_secret_data())
    else:
        update_secret(client.kube_secret_name, client.to_kubernetes_secret_data())


def list_secrets(namespaced_name: NamespacedName) -> list[str]:
    core_v1_api = kubeclient.CoreV1Api()
    secret_list = core_v1_api.list_namespaced_secret(namespaced_name.namespace)
    return [s.metadata.name for s in secret_list.items]


def create_secret(namespaced_name: NamespacedName, string_data: dict[str, str]) -> None:
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


def update_secret(namespaced_name: NamespacedName, string_data: dict[str, str]) -> None:
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


if __name__ == "__main__":
    main()
