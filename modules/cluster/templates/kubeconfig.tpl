apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${CA_CERT}
    server: https://${KUBERNETES_API_HOST}:${KUBERNETES_API_PORT}
  name: ${CLUSTER}
contexts:
- context:
    cluster: ${CLUSTER}
    user: ${USER_NAME}
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: ${USER_NAME}
  user:
    client-certificate-data: ${CLIENT_CERT}
    client-key-data: ${CLIENT_KEY}
