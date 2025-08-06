# kubernetes-ingress-nginx
kubernetes-ingress-nginx

In Kubernetes, Ingress is a powerful resource that manages external access to services within a cluster, typically over HTTP and HTTPS. However, the Ingress resource is just a set of rules—it doesn’t actually handle the network traffic by itself.

That’s where the Ingress Controller comes in. An Ingress Controller is a specialized load balancer that watches for changes to Ingress resources and fulfills them by configuring a proxy server (like NGINX, HAProxy, Envoy, etc.) accordingly. It acts as the gateway between external users and the internal services running in your cluster.


The NGINX Ingress Controller is one of the most widely used Ingress Controllers in the Kubernetes ecosystem. It uses NGINX, a high-performance web server and reverse proxy, to handle incoming requests and route them to the appropriate Kubernetes services.

It is maintained by the Kubernetes community under the kubernetes/ingress-nginx GitHub repo and supports advanced configurations through annotations, custom templates, and ConfigMaps.

There are two main variants:
1. Community NGINX Ingress Controller (ingress-nginx): Open-source and widely used.
2. NGINX Plus Ingress Controller: Enterprise-grade version maintained by F5 with commercial support.

We'll unravel the core concepts of Kubernetes Ingress, dive into its powerful features, and walk you through hands-on examples and best practices. Whether you're new to Kubernetes or an experienced user, our aim is to make Ingress easier to understand and enable you to make the most of its capabilities with confidence.

- [Part 1 – Understanding Ingress Controllers](https://dev.to/aws-builders/kubernetes-ingress-playlist-part-1-understanding-ingress-controllers-1mjj)
- [Part 2 – Installing NGINX Ingress on AWS EKS](https://dev.to/aws-builders/kubernetes-ingress-playlist-part-2-installing-nginx-ingress-controller-on-aws-eks-using-helm-14em)
- [Part 3 – Routing in NGINX Ingress Controller](https://dev.to/aws-builders/kubernetes-ingress-playlist-part-3-routing-in-nginx-ingress-controller-1jib)
- [Part 4 – Basic Authentication with NGINX Ingress](https://dev.to/aws-builders/kubernetes-ingress-playlist-part-4-basic-authentication-using-nginx-ingress-31jh)
- [Part 5 – HTTPS with Self-Signed TLS Certificates](https://dev.to/aws-builders/kubernetes-ingress-playlist-part-5-secure-your-app-with-https-using-self-signed-tls-certificates-5aa8)
- [Part 6 – HTTPS with Cert-Manager](https://dev.to/aws-builders/kubernetes-ingress-playlist-part-6-securing-the-kubernetes-ingress-using-cert-manager-with-https-cde)

Whether you're running applications in production or exploring Kubernetes in a test environment, mastering Ingress is key to efficiently managing external access. In this series, we’ll help you navigate the complexities of Kubernetes Ingress and equip you with the knowledge to build scalable, secure, and resilient applications within your cluster.