# Kubernetes Ingress Playlist Part 2- Installing NGINX Ingress Controller on AWS EKS using Helm

In earlier part of our Kubernetes Ingress Playlist, we understood what Kubernetes Ingress is and why it's important in simplifying external access to services within your cluster.

In this part, we'll take a hands-on approach to install the NGINX Ingress Controller on an Amazon EKS cluster using Helm, and expose it to the internet using an AWS Network Load Balancer (NLB).

### Why NGINX Ingress?
The NGINX Ingress Controller is one of the most widely adopted ingress controllers in the Kubernetes ecosystem. It's community-maintained and supports a wide range of use cases from basic path-based routing to advanced configurations like rate-limiting, TLS termination, and authentication.

### Step 0: Default Behavior — Classic Load Balancer
By default, when you install the NGINX Ingress Controller with service.type=LoadBalancer, Kubernetes on AWS will provision a Classic Load Balancer (CLB).

```bash
helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer
```

This may work for basic use cases, but for production workloads, it's recommended to use a Network Load Balancer (NLB) due to better performance, IP targeting, and TLS passthrough support.

### Step 1: Install NGINX Ingress Controller with NLB
To create a Network Load Balancer when we create ingress, we use an annotation supported by AWS:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb"
```

Output will look like:
```bash
NAME: ingress-nginx
LAST DEPLOYED: Sun Aug  3 22:38:43 2025
NAMESPACE: ingress-nginx
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the load balancer IP to be available.
You can watch the status by running 'kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide --watch'
```

This command installs the ingress controller in the ingress-nginx namespace and exposes it using a Kubernetes LoadBalancer type service and also adds an annotation that tells AWS to create a Network Load Balancer instead of a Classic Load Balancer

Once created, this NLB will automatically connect to the public subnets (if available) and expose an external IP.

```bash
$ kubectl get service --ns ingress-nginx ingress-nginx-controller 
NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP                                                                     PORT(S)                      AGE
ingress-nginx-controller   LoadBalancer   172.20.72.145   ad75493700bcd4c4db3470bdb08e9b2d-6739ce92cbd2f4d0.elb.us-east-1.amazonaws.com   80:30209/TCP,443:30549/TCP   4m33s
```

![alt text](/Part_02/images/nlb.png)

I own my domain and therefore I created an A record in route53 for the network load balancer created.

![alt text](/Part_02/images/reoute53_record.png)

### Step 2: Deploy a Simple Node.js App with a Service

Lets deploy our simple nodejs application using deployment and attach a service.

This creates a service named service-nodejs-app that forwards traffic on port 80 to port 8080 of the application pod. The selector matches pods with label app.kubernetes.io/name: nodejs-app.

Now the app is reachable within the cluster via this service.
```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: simple-nodejs-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: simple-nodejs-app
  name: deployment-nodejs-app
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: nodejs-app
  replicas: 5
  template:
    metadata:
      labels:
        app.kubernetes.io/name: nodejs-app
    spec:
      containers:
      - image: public.ecr.aws/n4o6g6h8/simple-nodejs-app:latest
        imagePullPolicy: Always
        name: nodejs-app
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  namespace: simple-nodejs-app
  name: service-nodejs-app
spec:
  type: ClusterIP
  ports:
    - port: 80
      name: http
      targetPort: 8080
  selector:
    app.kubernetes.io/name: nodejs-app
```

You can see the deployment and service has been created
```bash
$ kubectl get all -n simple-nodejs-app
NAME                                         READY   STATUS    RESTARTS   AGE
pod/deployment-nodejs-app-55555bc798-6b9qt   1/1     Running   0          2m 
pod/deployment-nodejs-app-55555bc798-b4gnl   1/1     Running   0          2m 
pod/deployment-nodejs-app-55555bc798-gwrws   1/1     Running   0          2m 
pod/deployment-nodejs-app-55555bc798-htfmk   1/1     Running   0          2m 
pod/deployment-nodejs-app-55555bc798-p4pbf   1/1     Running   0          2m 

NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/service-nodejs-app   ClusterIP   172.20.41.147   <none>        80/TCP    2m 

NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE        
deployment.apps/deployment-nodejs-app   5/5     5            5           2m1s      

NAME                                               DESIRED   CURRENT   READY   AGE 
replicaset.apps/deployment-nodejs-app-55555bc798   5         5         5       2m1s
```

### Step 3: Create Ingress Resource to Route Traffic
Create an Ingress resource to route incoming traffic from the NLB through the ingress controller to the internal Node.js service.

Here’s a sample ingress manifest:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-nodejs-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
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

Replace <YOUR_DOMAIN_OR_NLB_DNS> with either the NLB DNS name (for testing) or your actual domain name (configured in Route 53), I have configured my own domain.

The annotation rewrite-target: / ensures that the request URI is rewritten properly when forwarding to the backend. This resource tells the ingress controller: "If someone hits / on this domain, forward traffic to simple-nodejs-service on port 80".

Apply and see nginx ingress created:

```bash
$ kubectl get ingress -n simple-nodejs-app
NAME                    CLASS   HOSTS           ADDRESS   PORTS   AGE
simple-nodejs-ingress   nginx   chinmayto.com             80      35s
```

### Step 4: Access the App via External DNS
Test if traffic from the internet hits our NLB, goes through the ingress controller, and reaches the Node.js app.

Open a browser or use curl to access:
```bash
http://<HOST-NAME> # chinmay.to in our case
```
You should see the homepage or output of your Node.js app!

![alt text](/Part_02/images/nodejs_app.png)

### Conclusion
In this second part of our Kubernetes Ingress Playlist, you successfully took a practical step forward: installing the NGINX Ingress Controller on Amazon EKS. You learned how the controller works by default, typically provisioning a Classic Load Balancer, and how to switch to a Network Load Balancer for a production-grade, highly-performant ingress setup.

We also showed how to create an Ingress resource to route external traffic to a simple Node.js app, allowing you to see the end-to-end flow:
```bash
Client → NLB → NGINX Ingress → Kubernetes Service → Application Pod
```

This foundational pattern is a building block for modern microservices architectures on Kubernetes.

### References
AWS Documentation: https://aws.amazon.com/blogs/containers/exposing-kubernetes-applications-part-3-nginx-ingress-controller/