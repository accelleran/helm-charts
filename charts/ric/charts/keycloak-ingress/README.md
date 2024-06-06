# Export keycloak config to json file from command line

1) Log into keycloak pod
kubectl exec -it ric-keycloak-0 -- /bin/bash

2) Go in the bin folder
cd /opt/jboss/keycloak/bin

3) Export current keycloak config with realm name RIC into a keycloak.save file
./standalone.sh -Dkeycloak.migration.action=export -Dkeycloak.migration.provider=singleFile -Dkeycloak.migration.file=keycloak.save -Dkeycloak.migration.realmName=RIC -Dkeycloak.migration.usersExportStrategy=REALM_FILE -Djboss.socket.binding.port-offset=99

4) The exported configuration can be used to add config or compare values in the templates/configmap-realm.yaml

