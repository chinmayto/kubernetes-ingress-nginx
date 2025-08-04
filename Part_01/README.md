# Kubernetes Ingress Playlist Part 1 - Understanding Ingress Controllers

As organizations adopt microservices architecture and Kubernetes for deploying containerized applications, one critical question arises:

“How do external users securely access my services running inside the Kubernetes cluster?”

By default, Kubernetes provides service types like ClusterIP, NodePort, and LoadBalancer to expose applications. However:

- ClusterIP only allows internal access.
- NodePort exposes your app on every node's IP and a static port — not ideal for production.
- LoadBalancer provisions a cloud provider load balancer — but one per service, which is expensive and harder to manage at scale.

Imagine a production app with:
- A frontend UI service
- A backend API service
- An admin dashboard
- A metrics endpoint

If you use LoadBalancer for each, you’ll quickly rack up cloud costs and lose centralized control.

### What is Kubernetes Ingress ?
Kubernetes Ingress is the Kubernetes-native solution for managing external access to your services. It acts as a reverse proxy and traffic director, intelligently routing requests based on hostname, path, or even headers — all from a single IP address or DNS name.

It helps you:
- Serve multiple services behind one domain
- Apply routing logic without touching individual services
- Secure traffic using TLS/SSL
- Manage load balancing across pods
- Implement rewrites, redirects, authentication, and more

In short, Ingress is the traffic controller at the edge of your Kubernetes cluster. It gives you control, flexibility, and security.

To make this work, you also need an Ingress Controller, which is the engine that reads your Ingress rules and translates them into real-world proxy configurations (like NGINX or AWS ALB).

### 1. An Introduction to Kubernetes Ingress
By default, Kubernetes exposes services using NodePort or LoadBalancer types. While these work for small apps, they don’t scale well for production environments with multiple services.

Kubernetes Ingress is an API object that defines HTTP/HTTPS routing rules to expose services outside the cluster. It's the Kubernetes-native way to expose multiple services over a single IP or domain.

###  2. Ingress Controllers: Making Ingress Work
The Ingress resource itself is just a configuration. You need an Ingress Controller to process those rules and handle the actual traffic routing.

What is an Ingress Controller?
It is a Kubernetes pod (usually a proxy server like NGINX, HAProxy, etc.) that watches the cluster for Ingress objects and applies the specified rules.

Popular Ingress Controllers:

- NGINX Ingress Controller (Open-source, CNCF maintained)
- AWS Load Balancer Controller (For Amazon EKS)
- Traefik, Contour, Istio Gateway (in service mesh environments)

How it works:
- Deploy the controller into your cluster
- Define Ingress resources
- The controller dynamically updates routing rules


### 3. Routing Traffic with Ingress Rules
Ingress rules define the way the traffic is routed to underlying resources
- Host-based: Route by domain (api.example.com, admin.example.com)
- Path-based: Route by URL path (/login, /users)
- Header-based: Supported in advanced ingress controllers

### 4. Securing Ingress with TLS
One of the most powerful features of Ingress is SSL/TLS termination, i.e., decrypting HTTPS traffic at the ingress level.

You can use:
- AWS ACM (with AWS Load Balancer Controller)
- cert-manager (with NGINX or other controllers)
- Let’s Encrypt certificates

### 5. Advanced Ingress Features
Ingress becomes even more powerful with annotations and controller-specific configurations.
- URL Rewrites: Modify incoming request paths before forwarding them to backend services.
- Load Balancing: Distribute traffic evenly across multiple pod replicas.
- Rate Limiting: Control the number of requests a client can make over time.
- Request Header Manipulation: Add or modify headers before passing requests to services.
- Authentication: Protect endpoints using basic auth, JWT, or external identity providers.
- gRPC and WebSocket Support: Handle modern protocols for real-time and streaming applications.
- Canary Releases: Split traffic between versions for safer deployments and A/B testing.


### AWS Load Balancer Controller vs NGINX Ingress Controller

Both AWS Load Balancer Controller and NGINX Ingress Controller serve the same core purpose — managing external access to Kubernetes services — but they take very different approaches, each with distinct advantages depending on your architecture and goals.


### Conclusion
Kubernetes Ingress is a powerful and essential component for managing external access to your applications in a scalable, secure, and efficient manner. It allows you to consolidate and control HTTP/HTTPS traffic through a single entry point, enabling features like path- and host-based routing, TLS termination, and advanced traffic management.

Choosing the right Ingress Controller depends heavily on your use case:
- If you're fully invested in AWS and want a managed, integrated solution with native support for ACM, WAF, and ALB/NLB — go with the AWS Load Balancer Controller.
- If you need flexibility, advanced routing features, portability across cloud environments, or deep customization — the NGINX Ingress Controller is the better fit.

As your Kubernetes workloads grow, setting up Ingress properly will not only streamline traffic management but also improve the security, maintainability, and observability of your platform.

Whether you're building on AWS, on-prem, or across multiple clouds — Ingress is your gateway to production-grade Kubernetes networking.