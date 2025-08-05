# Kubernetes Ingress - Part 4: Basic Authentication using NGINX Ingress

In the previous parts of this playlist, we explored what Ingress is, installed the NGINX Ingress Controller on AWS EKS, and configured routing rules. In this part, we’ll focus on 
securing access to our application using Basic Authentication with NGINX Ingress.

We’ll use the same simple-nodejs-app deployed on EKS as the backend service.

### What is Basic Authentication?
Basic Authentication is a simple authentication mechanism where a client provides a username and password with each HTTP request. While not the most secure form of authentication (especially without HTTPS), it's quick and useful for internal applications or early-stage deployments.

### Prerequisites
1. A working Kubernetes cluster with NGINX Ingress Controller installed (we're using AWS EKS).
2. kubectl configured to access your cluster.
3. htpasswd utility installed locally (can be installed via apache2-utils or httpd-tools).

### Step 1: Create a Password File using htpasswd
Generate a password file using the htpasswd command. For example:

```bash
htpasswd -c auth adminuser
```
You'll be prompted to enter a password. This creates a file called `auth` with credentials for user adminuser.

### Step 2: Create a Kubernetes Secret with the Credentials
Create a Kubernetes secret from the generated htpasswd file:

```bash
kubectl create secret generic basic-auth --from-file=auth -n simple-nodejs-app
```

This creates a secret named basic-auth in the default namespace.

### Step 3: Create an Ingress Resource with Basic Auth Annotations

Create manifest file (nginx-ingress-basic-auth.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-nodejs-ingress
  namespace: simple-nodejs-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    # type of authentication
    nginx.ingress.kubernetes.io/auth-type: "basic"
    # name of the secret that contains the user/password definitions
    nginx.ingress.kubernetes.io/auth-secret: "basic-auth"
    # message to display with an appropriate context why the authentication is required
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
spec:
  ingressClassName: nginx
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

Make sure host chinmayto.com points to your Ingress controller's external IP (via /etc/hosts entry or Route53 record).

Apply it using command:
```bash
kubectl apply -f nginx-ingress-basic-auth.yaml
```

Access it using the host name http://chinmayto.com

![alt text](/Part_04/images/basic_auth.png)

![alt text](/Part_04/images/auth_success.png)

### Conclusion
In this part of the Kubernetes Ingress playlist, we explored how to secure access to applications using generic Basic Authentication with the NGINX Ingress Controller. Basic Auth provides a straightforward mechanism to restrict access by requiring a valid username and password before users can reach your application.

This method is especially useful for quickly protecting internal tools, development environments, or staging applications without setting up a full-fledged authentication system. While it should not be considered a comprehensive security measure—especially without HTTPS—it serves as a simple and effective first layer of protection in many use cases.

### References
1. GitHub Repo: https://github.com/chinmayto/kubernetes-ingress-nginx/tree/main/Part_04