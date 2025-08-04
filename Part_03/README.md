# Kubernetes Ingress Playlist – Part 3: Routing in NGINX Ingress Controller

In the previous parts of the playlist, we learned what Ingress is and how to install the NGINX Ingress Controller on AWS EKS.
Now in Part 3, we’ll explore how routing works in the NGINX Ingress Controller with practical examples using two simple Node.js applications:

`simple-nodejs-app-1`
`simple-nodejs-app-2`

Let’s dive into the different types of routing supported by the NGINX Ingress Controller.

First of all we will deploy above 2 applications in separate deployments with a service.

Deploy first app:
```bash
kubectl apply -f https://raw.githubusercontent.com/chinmayto/kubernetes-ingress-nginx/main/Part_03/deploy-simple-nodejs-app-1.yaml
```

Deploy second app:
```bash
kubectl apply -f https://raw.githubusercontent.com/chinmayto/kubernetes-ingress-nginx/main/Part_03/deploy-simple-nodejs-app-1.yaml
```

See that both apps have been deployed. First app exposes services to targetPort 8080 and second one at targetPort 8081.
```bash
$ kubectl get svc,pod -n simple-nodejs-app
NAME                           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
service/service-nodejs-app-1   ClusterIP   172.20.232.156   <none>        80/TCP    37s
service/service-nodejs-app-2   ClusterIP   172.20.80.39     <none>        80/TCP    26s

NAME                                           READY   STATUS    RESTARTS   AGE        
pod/deployment-nodejs-app-1-5cc7b94fd8-9dcsx   1/1     Running   0          38s        
pod/deployment-nodejs-app-1-5cc7b94fd8-zs477   1/1     Running   0          38s
pod/deployment-nodejs-app-2-7fc47d7995-9klmv   1/1     Running   0          26s
pod/deployment-nodejs-app-2-7fc47d7995-fc94w   1/1     Running   0          26s
```

NGINX Ingress routing is the process of directing external HTTP or HTTPS traffic to services running inside a Kubernetes cluster using the NGINX Ingress Controller. It acts as a smart reverse proxy that sits at the edge of the cluster and inspects incoming requests to determine how they should be forwarded based on predefined rules. These rules can be based on the request’s path, host (domain), headers, or even custom conditions. 

By using NGINX for ingress routing, you can consolidate access to multiple applications through a single IP address or load balancer, enforce routing logic, and apply advanced traffic management strategies like TLS termination, canary deployments, and authentication. It offers a powerful, flexible, and production-ready way to expose Kubernetes services to the outside world.

### 1) Basic Routing
Basic routing is the simplest form of ingress routing where all incoming HTTP requests, regardless of the path or host, are directed to a single backend service. It is typically used when your Kubernetes cluster hosts only one web application or when you want all users to land on a common frontend. This setup is straightforward and often serves as the default routing mechanism for monolithic applications deployed on Kubernetes.

Create a manifest file (nginx-ingress-basic-routing.yaml)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-nodejs-ingress
  namespace: simple-nodejs-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: service-nodejs-app-1
                port:
                  number: 80
```

Apply it and see its details
```bash
$ kubectl apply -f nginx-ingress-basic-routing.yaml 

$ kubectl get ingress -n simple-nodejs-app
NAME                    CLASS   HOSTS   ADDRESS                                                                         PORTS   AGE
simple-nodejs-ingress   nginx   *       a602f172c106e4d4eb0736290c756d76-6d3fef0920a1c9a1.elb.us-east-1.amazonaws.com   80      57s
```

Access it using the `http://<NLB-DNS>/`

![alt text](/Part_03/images/basic-routing.png)

### 2) Path-Based Routing
Path-based routing allows you to route traffic to different services based on the URL path in the incoming request. For example, requests to /app1 can be routed to one service, while /app2 can go to another. This is particularly useful in a microservices architecture where different applications or modules are served under specific paths on the same domain. It enables clean separation of concerns and efficient resource utilization under a shared ingress endpoint.

Create a manifest file (nginx-ingress-path-based-routing.yaml)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-nodejs-ingress
  namespace: simple-nodejs-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: chinmayto.com
      http:
        paths:
          - path: /app1
            pathType: Prefix
            backend:
              service:
                name: service-nodejs-app-1
                port:
                  number: 80
          - path: /app2
            pathType: Prefix
            backend:
              service:
                name: service-nodejs-app-2
                port:
                  number: 80
```

Apply it and see its details
```bash
$ kubectl apply -f nginx-ingress-path-based-routing.yaml 

$ kubectl get ingress -n simple-nodejs-app
NAME                    CLASS   HOSTS           ADDRESS   PORTS   AGE
simple-nodejs-ingress   nginx   chinmayto.com             80      14s
```

Add an `A` record in route53 for `chinmayto.com` pointing to NLB.

Access it using the `http://chinmayto.com/app1` and `http://chinmayto.com/app2`

![alt text](/Part_03/images/path-routing-1.png)

![alt text](/Part_03/images/path-routing-2.png)

### 3) Host-Based Routing
Host-based routing allows the Ingress Controller to make routing decisions based on the HTTP Host header. It is ideal when you want to serve multiple applications using different domain names or subdomains. For instance, app1.example.com can route to one application while app2.example.com can point to another. This is commonly used in multi-tenant architectures or when consolidating services under one Ingress Controller while maintaining domain isolation.

Create the manifest file (nginx-ingress-host-based-routing.yaml)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-nodejs-ingress
  namespace: simple-nodejs-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: app1.chinmayto.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: service-nodejs-app-1
                port:
                  number: 80
    - host: app2.chinmayto.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: service-nodejs-app-2
                port:
                  number: 80
```

Apply it and see its details
```bash
$ kubectl apply -f nginx-ingress-host-based-routing.yaml 

$ kubectl get ingress -n simple-nodejs-app
NAME                    CLASS   HOSTS                                   ADDRESS                                                                         PORTS   AGE
simple-nodejs-ingress   nginx   app1.chinmayto.com,app2.chinmayto.com   a602f172c106e4d4eb0736290c756d76-6d3fef0920a1c9a1.elb.us-east-1.amazonaws.com   80      9m52s
```

Add two `A` records in route53 for `app1.chinmayto.com` and `app2.chinmayto.com` pointing to NLB.

Access it using the `http://app1.chinmayto.com` and `http://app2.chinmayto.com`

![alt text](/Part_03/images/host-routing-1.png)

![alt text](/Part_03/images/host-routing-2.png)

### 4) Wildcard Routing
Wildcard routing enables you to match multiple subdomains under a base domain using wildcard patterns like *.example.com. This is useful when you need to serve dynamically generated subdomains, such as for user-specific dashboards (user1.example.com, user2.example.com, etc.), without having to declare each one individually in the Ingress rules. It simplifies routing management in environments that require scalability with subdomain patterns.

Create manifest file (nginx-ingress-wildcard-routing.yaml)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-nodejs-ingress
  namespace: simple-nodejs-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: "*.chinmayto.com"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: service-nodejs-app-1
                port:
                  number: 80
```

Apply it and see its details
```bash
$ kubectl apply -f nginx-ingress-wildcard-routing.yaml 

$ kubectl get ingress -n simple-nodejs-app
NAME                    CLASS   HOSTS             ADDRESS   PORTS   AGE
simple-nodejs-ingress   nginx   *.chinmayto.com             80      7s
```

Add an `A` records in route53 for `*.chinmayto.com` pointing to NLB.

Access it using the `http://anything.chinmayto.com`

![alt text](/Part_03/images/wildcard-routing.png)

### 5) Regex-Based Routing
Regex-based routing adds powerful pattern-matching capabilities to your ingress rules by allowing regular expressions in path definitions. This is helpful when you want to match complex or optional URL structures, such as /api/v1/.* or /app1(/|$)(.*). It enables more dynamic routing configurations but requires careful rule writing and the use of specific annotations and path types. It’s especially handy when URL structures cannot be strictly controlled.

Create manifest file (nginx-ingress-regex-based-routing.yaml)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-nodejs-ingress
  namespace: simple-nodejs-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
    - host: chinmayto.com
      http:
        paths:
          - path: /app1(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: service-nodejs-app-1
                port:
                  number: 80
          - path: /app2(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: service-nodejs-app-2
                port:
                  number: 80
```

Apply it and see its details
```bash
$ kubectl apply -f nginx-ingress-regex-based-routing.yaml 

$ kubectl get ingress -n simple-nodejs-app
NAME                    CLASS   HOSTS           ADDRESS                                                                         PORTS   AGE
simple-nodejs-ingress   nginx   chinmayto.com   a602f172c106e4d4eb0736290c756d76-6d3fef0920a1c9a1.elb.us-east-1.amazonaws.com   80      7s
```

Add an `A` records in route53 for `chinmayto.com` pointing to NLB.

Access it using the `http://chinmayto.com/app1/anything`

![alt text](/Part_03/images/regex-routing.png)

### 6) Canary Routing
Canary routing enables progressive delivery by allowing a portion of traffic to be routed to a "canary" version of a service. This is useful for testing new versions of applications in production with real users but limited exposure. For example, only 10% of traffic might hit the canary app while 90% continues to go to the stable version. This technique is essential for safe deployments, A/B testing, and minimizing risk during upgrades.

Create manifest for stable version (nginx-ingress-canary-based-stable-version.yaml)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-nodejs-ingress-stable
  namespace: simple-nodejs-app
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
                name: service-nodejs-app-1
                port:
                  number: 80
```

Create another manifest for canary version (nginx-ingress-canary-based-canary-version.yaml)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-nodejs-ingress-canary
  namespace: simple-nodejs-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "20"
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
                name: service-nodejs-app-2
                port:
                  number: 80

```

Apply both and see details
```bash
$ kubectl apply -f nginx-ingress-canary-based-stable-version.yaml 
$ kubectl apply -f nginx-ingress-canary-based-canary-version.yaml 

$  kubectl get ingress -A
NAMESPACE           NAME                           CLASS   HOSTS           ADDRESS                                                                         PORTS   AGE
simple-nodejs-app   simple-nodejs-ingress-canary   nginx   chinmayto.com   a602f172c106e4d4eb0736290c756d76-6d3fef0920a1c9a1.elb.us-east-1.amazonaws.com   80      8m5s
simple-nodejs-app   simple-nodejs-ingress-stable   nginx   chinmayto.com   a602f172c106e4d4eb0736290c756d76-6d3fef0920a1c9a1.elb.us-east-1.amazonaws.com   80      8m15s
```

Add an `A` records in route53 for `chinmayto.com` pointing to NLB.

Access it using the `http://chinmayto.com` and you will see the requests going to both the applications when you refresh.

### Conclusion
In this part, we explored the powerful routing capabilities of the NGINX Ingress Controller in Kubernetes. From basic routing to more advanced techniques like path-based, host-based, wildcard, and canary routing, NGINX offers fine-grained control over how traffic is directed to services inside your cluster. We used simple Node.js apps to demonstrate each routing strategy and highlighted how these approaches work in real-world EKS setups, including how to configure DNS using Route 53.

Whether you're building a multi-tenant platform, deploying versioned microservices, or experimenting with blue-green or canary deployments, mastering Ingress routing is a crucial step toward designing reliable, scalable, and production-grade Kubernetes applications.

### References:
GitHub Repo: https://github.com/chinmayto/kubernetes-ingress-nginx/tree/main/Part_03