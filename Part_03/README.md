# Kubernetes Ingress Playlist – Part 3: Routing in NGINX Ingress Controller

In the previous parts of the playlist, we learned what Ingress is and how to install the NGINX Ingress Controller on AWS EKS.
Now in Part 3, we’ll explore how routing works in the NGINX Ingress Controller with practical examples using two simple Node.js applications:

`simple-nodejs-app-1`
`simple-nodejs-app-2`

Let’s dive into the different types of routing supported by the NGINX Ingress Controller.


NGINX Ingress routing is the process of directing external HTTP or HTTPS traffic to services running inside a Kubernetes cluster using the NGINX Ingress Controller. It acts as a smart reverse proxy that sits at the edge of the cluster and inspects incoming requests to determine how they should be forwarded based on predefined rules. These rules can be based on the request’s path, host (domain), headers, or even custom conditions. 

By using NGINX for ingress routing, you can consolidate access to multiple applications through a single IP address or load balancer, enforce routing logic, and apply advanced traffic management strategies like TLS termination, canary deployments, and authentication. It offers a powerful, flexible, and production-ready way to expose Kubernetes services to the outside world.

### 1) Basic Routing
Basic routing is the simplest form of ingress routing where all incoming HTTP requests, regardless of the path or host, are directed to a single backend service. It is typically used when your Kubernetes cluster hosts only one web application or when you want all users to land on a common frontend. This setup is straightforward and often serves as the default routing mechanism for monolithic applications deployed on Kubernetes.