# Part 6: Securing the Kubernetes Ingress Using Cert-Manager with HTTPS
In the previous parts of our Kubernetes Ingress playlist, we covered installing the NGINX Ingress Controller, implementing host/path-based routing, and enabling authentication and self-signed TLS. Now, it's time to move a step ahead and automate certificate management using Cert-Manager — a powerful tool that simplifies issuing and renewing SSL/TLS certificates within your Kubernetes cluster.

In this part, we’ll:

1. Deploy the simple-nodejs-app
2. Install and configure Cert-Manager
3. Automatically issue TLS certificates via Let’s Encrypt using ClusterIssuer
4. Secure our NGINX Ingress endpoint with HTTPS

### What is Cert-Manager?
Cert-Manager is a native Kubernetes certificate management controller that helps manage and automate the issuance, renewal, and use of TLS certificates. It supports multiple certificate issuers such as:
1. Let’s Encrypt (ACME)
2. HashiCorp Vault
3. Self-signed certificates
4. Venafi, and more

With Cert-Manager, you don’t need to manually generate and rotate certificates. It integrates seamlessly with Kubernetes and works great with Ingress resources.

As in previous parts, we’ll use the simple-nodejs-app exposed via a Kubernetes Service and secured via Ingress. The key difference this time is: we'll use Cert-Manager to get a real TLS certificate from Let’s Encrypt, making HTTPS truly production-ready.

###  Step 1: Install Cert-Manager using Helm

We will use helm to install cert manager. Following commands will install the Cert-Manager controller and its required CustomResourceDefinitions (CRDs).

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.3 \
  --set installCRDs=true
```
You will see output:

```bash
NAME: cert-manager
LAST DEPLOYED: Wed Aug  6 00:16:00 2025
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
cert-manager v1.14.3 has been deployed successfully!
```
You can verify the installation
```bash
$ kubectl get pods --namespace cert-manager
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-6c4645d66c-vlrd7              1/1     Running   0          4m23s
cert-manager-cainjector-55c5b94bfc-mnhln   1/1     Running   0          4m23s
cert-manager-webhook-549d7475d7-f9rzw      1/1     Running   0          4m23s
```

### Step 2: Create a ClusterIssuer for Let’s Encrypt (Staging)

Cert-Manager needs an Issuer to request certificates from a Certificate Authority (CA) like Let’s Encrypt. We’ll create a ClusterIssuer, which issues certificates for the entire Kubernetes cluster. You can create a ClusterIssuer in any namespace — it's a cluster-wide resource, not namespace-scoped.

Create manifest (cluster_issuer.yaml)
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-nginx-cert
spec:
  # ACME issuer configuration
  # `email` - the email address to be associated with the ACME account (make sure it's a valid one)
  # `server` - the URL used to access the ACME server’s directory endpoint
  # `privateKeySecretRef` - Kubernetes Secret to store the automatically generated ACME account private key
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: newabog237@misehub.com
    privateKeySecretRef:
      name: letsencrypt-nginx-cert
    solvers:
      - http01:
          ingress:
            class: nginx
```

Apply it and verify it:
```bash
$ kubectl apply -f cluster_issuer.yaml 
clusterissuer.cert-manager.io/letsencrypt-ngionx-cert created

$ kubectl get clusterissuer.cert-manager.io/letsencrypt-nginx-cert
NAME                     READY   AGE
letsencrypt-nginx-cert   True    4m20s
```

### Step 3: Create a TLS-enabled Ingress
Cert-Manager will automatically provision a TLS certificate and store it in the `simple-nodejs-tls-secret` secret.

Create manifest file (nginx-ingress-with-cert-manager.yaml)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-nodejs-ingress
  namespace: simple-nodejs-app
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-nginx-cert"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - chinmayto.com
      secretName: simple-nodejs-tls-secret
  rules:
    - host: chinmayto.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: service-nodejs-app
                port:
                  number: 80
```

Apply it and verify:
```bash
$ kubectl apply -f nginx-ingress-with-cert-manager.yaml 
ingress.networking.k8s.io/simple-nodejs-ingress created

$ kubectl get ingress -n simple-nodejs-app
NAME                    CLASS   HOSTS           ADDRESS                                                                         PORTS     AGE
simple-nodejs-ingress   nginx   chinmayto.com   a4374e0452f8c4e0c99602307d9cb013-4fe3550df37ae3d7.elb.us-east-1.amazonaws.com   80, 443   43s

$ kubectl get secret -n simple-nodejs-app
NAME                       TYPE                DATA   AGE
simple-nodejs-tls-secret   kubernetes.io/tls   2      23s
```

This will also create a certificate, describe it to get event log:
```bash
$ kubectl get certificate -n simple-nodejs-app
NAME                       READY   SECRET                     AGE
simple-nodejs-tls-secret   True    simple-nodejs-tls-secret   64s

$ kubectl describe certificate -n simple-nodejs-app
Name:         simple-nodejs-tls-secret
Namespace:    simple-nodejs-app
Labels:       <none>
Annotations:  <none>
API Version:  cert-manager.io/v1
Kind:         Certificate
Metadata:
  Creation Timestamp:  2025-08-05T19:25:19Z
  Generation:          1
  Owner References:
    API Version:           networking.k8s.io/v1
    Block Owner Deletion:  true
    Controller:            true
    Kind:                  Ingress
    Name:                  simple-nodejs-ingress
    UID:                   60ff8b31-a5d0-43ef-a01d-d50c308870ab
  Resource Version:        14728
  UID:                     17601f42-7597-44c8-be5e-096434d8be46
Spec:
  Dns Names:
    chinmayto.com
  Issuer Ref:
    Group:      cert-manager.io
    Kind:       ClusterIssuer
    Name:       letsencrypt-nginx-cert
  Secret Name:  simple-nodejs-tls-secret
  Usages:
    digital signature
    key encipherment
Status:
  Conditions:
    Last Transition Time:  2025-08-05T19:25:42Z
    Message:               Certificate is up to date and has not expired
    Observed Generation:   1
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Not After:               2025-11-03T18:27:11Z
  Not Before:              2025-08-05T18:27:12Z
  Renewal Time:            2025-10-04T18:27:11Z
  Revision:                1
Events:
  Type    Reason     Age    From                                       Message
  ----    ------     ----   ----                                       -------
  Normal  Issuing    3m26s  cert-manager-certificates-trigger          Issuing certificate as Secret does not exist
  Normal  Generated  3m25s  cert-manager-certificates-key-manager      Stored new private key in temporary Secret resource "simple-nodejs-tls-secret-vcvkp"
  Normal  Requested  3m25s  cert-manager-certificates-request-manager  Created new CertificateRequest resource "simple-nodejs-tls-secret-1"
  Normal  Issuing    3m3s   cert-manager-certificates-issuing          The certificate has been successfully issued
```

Now access `https://chinmayto.com` in your browser and inspect the certificate. It should be signed by Let’s Encrypt. Even if you try to access `http://chinmayto.com` it gets redirected to https.

![alt text](/Part_06/images/secure-website.png)

![alt text](/Part_06/images/valid-cert.png)

Note: If by any reason certificate status is not READY, try to get reason by describing it. If there is an issue issuing certificate, describe the `challenge` to troubleshoot.

### Conclusion
Using Cert-Manager, we’ve automated the entire TLS certificate lifecycle within our Kubernetes cluster. Instead of relying on self-signed certs or manual renewals, Cert-Manager:

1. Automatically provisions and renews certificates
2. Integrates with Ingress resources for seamless HTTPS
3. Supports both staging and production issuers

This boosts security, ensures reliability, and simplifies operational overhead. It’s a production-grade solution for securing Kubernetes services via Ingress and a must-have for modern cloud-native applications.