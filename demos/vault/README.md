# Install
```shell
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault --set server.dev.enabled=true
kubectl get pods
kubectl port-forward svc/vault 8200:8200
export VAULT_ADDR='http://127.0.0.1:8200'
```

# K8s demo
Integrating HashiCorp Vault secrets into Kubernetes pods typically involves leveraging Vault's Kubernetes authentication method and a sidecar pattern or using a secrets management tool like Vault's CSI provider. Here's a simplified example of how you could pull a secret from Vault into a Kubernetes container using an init container and the Vault Agent. This method automates the retrieval of secrets from Vault and makes them available to your application container at startup.

### Prerequisites

- A running Vault server configured with the Kubernetes authentication method.
- A Kubernetes cluster with RBAC enabled.
- A service account in Kubernetes that has permissions to access the Vault secrets.
- A Vault policy that grants access to the required secrets.

### Step 1: Create a Vault Policy

First, create a Vault policy that grants access to the secrets. Suppose you have a secret stored at `secret/data/myapp/config`, your policy might look like this:

```hcl
path "secret/data/myapp/config" {
  capabilities = ["read"]
}
```

Apply this policy to Vault, naming it `myapp-policy`.

### Step 2: Configure Kubernetes Authentication in Vault

You need to enable and configure the Kubernetes authentication method in Vault to allow Kubernetes pods to authenticate with Vault using their service account tokens.

1. Enable Kubernetes auth method:

   ```shell
   vault auth enable kubernetes
   ```

2. Configure it to talk to your Kubernetes API:

   ```shell
   vault write auth/kubernetes/config \
     token_reviewer_jwt="<token_reviewer_jwt>" \
     kubernetes_host="https://<kubernetes_host>:<port>" \
     kubernetes_ca_cert=@/path/to/ca.crt
   ```

3. Create a role that maps Kubernetes service accounts to Vault policies:

   ```shell
   vault write auth/kubernetes/role/myapp \
     bound_service_account_names=myapp-service-account \
     bound_service_account_namespaces=default \
     policies=myapp-policy \
     ttl=1h
   ```

### Step 3: Create a Service Account in Kubernetes

Create a service account in Kubernetes that your application will use. This service account is bound to the Vault role.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp-service-account
  namespace: default
```

### Step 4: Deploy Your Application with an Init Container

Deploy your application with an init container that uses the Vault Agent to authenticate with Vault using the service account token and retrieve the secret.

Here's an example Deployment manifest:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      serviceAccountsName: myapp-service-account
      initContainers:
        - name: vault-init
          image: vault:1.7.0
          args:
            - "agent"
            - "-config=/etc/vault/agent-config.hcl"
          env:
            - name: VAULT_ADDR
              value: "http://vault:8200"
          volumeMounts:
            - name: vault-secrets
              mountPath: /etc/vault/secrets
            - name: config
              mountPath: /etc/vault
      containers:
        - name: myapp
          image: myapp:latest
          volumeMounts:
            - name: vault-secrets
              mountPath: /etc/secrets
              readOnly: true
      volumes:
        - name: vault-secrets
          emptyDir: {}
        - name: config
          configMap:
            name: vault-agent-config
```

This manifest assumes you have a ConfigMap `vault-agent-config` that contains your Vault Agent configuration, including how to authenticate with Vault and which secrets to retrieve.

### Step 5: Create the ConfigMap for Vault Agent Configuration

You need a ConfigMap that holds the configuration for the Vault Agent. The agent config might look like this:

```hcl
exit_after_auth = true
pid_file = "/home/vault/pidfile"

auto_auth {
  method "kubernetes" {
    mount_path = "auth/kubernetes"
    config = {
      role = "myapp"
    }
  }

  sink "file" {
    config = {
      path = "/home/vault/.vault-token"
    }
  }
}

template {
  source      = "/etc/vault/secrets/template.ctmpl"
  destination = "/etc/vault/secrets/config.json"
}
```

And the `template.ctmpl` file would contain the Go template that specifies how to render the secret into a file:

```liquid
{{ with secret "secret/data/myapp/config" }}
{
  "username": "{{ .Data.data.username }}",
  "password": "{{ .Data.data.password }}"
}
{{ end }}
```

Remember to adjust paths, role names, secret locations, and other configuration details to match your

 environment and needs. This approach automates the process of fetching secrets for your application, keeping the secret material out of your container images and environment variables.
