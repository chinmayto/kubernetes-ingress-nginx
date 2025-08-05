# Part 5: Secure Your App with HTTPS using Self-Signed TLS Certificates in Kubernetes Ingress

So far in our Kubernetes Ingress playlist, we've covered what Ingress is, how to install NGINX Ingress Controller, configure routing, and enable basic authentication. In this part, we'll take it a step further by enabling HTTPS on your application using self-signed TLS certificates.

While in production environments you should always use trusted Certificate Authorities (e.g., via Let's Encrypt or AWS ACM), self-signed certs are useful in dev/test environments or for internal services where you control the client machines.

We will secure our simple-nodejs-app which is already exposed via Ingress and add a TLS layer on top using a self-signed certificate. I have already deployed the pod with service and added an A record in Route 53 for NLB dns name.

### Step 1. Generate Self-Signed TLS Certificate

Use the following command to generate a cert and private key:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=chinmayto.com/O=SimpleNodeApp"
```
This generates:
1. `tls.crt`: the self-signed certificate
2. `tls.key`: the private key


### Step 2. Create a Kubernetes Secret
Use the TLS files to create a Kubernetes secret in the same namespace as your app:

```bash
kubectl create secret tls simple-nodejs-tls-secret \
  --cert=tls.crt \
  --key=tls.key \
  -n simple-nodejs-app
```

You can verify it with:
```bash
kubectl get secret simple-nodejs-tls-secret -n simple-nodejs-app -o yaml
```
### Step 3. Create or Update Ingress Resource for TLS
Create the manifest file (nginx-ingress-self-signed-tls-auth.yaml)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-nodejs-ingress
  namespace: simple-nodejs-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - chinmayto
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

Make sure host chinmayto.com points to your Ingress controller's external IP (via /etc/hosts entry or Route53 record).

Apply it using command:
```bash
kubectl apply -f nginx-ingress-self-signed-tls-auth.yaml
```
### Step 5. Access the App via HTTPS
Now open your browser and go to: https://chinmayto.com

Since this is a self-signed certificate, your browser will display a security warning like: `“Your connection is not private”`. You can safely bypass this for testing purposes.

![alt text](/Part_05/images/website.png)

### Step 6. Test with curl
Following command will give us the `308 Permanent Redirect` since we are accessing over HTTP and not HTTPS.
```bash
$ curl -v http://chinmayto.com -k
* Host chinmayto.com:80 was resolved.
* IPv6: (none)
* IPv4: 18.214.175.186, 3.216.204.203
*   Trying 18.214.175.186:80...
* Connected to chinmayto.com (18.214.175.186) port 80
> GET / HTTP/1.1
> Host: chinmayto.com
> User-Agent: curl/8.8.0
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 308 Permanent Redirect
< Date: Tue, 05 Aug 2025 10:18:47 GMT
< Content-Type: text/html
< Content-Length: 164
< Connection: keep-alive
< Location: https://chinmayto.com
<
<html>
<head><title>308 Permanent Redirect</title></head>
<body>
<center><h1>308 Permanent Redirect</h1></center>
<hr><center>nginx</center>
</body>
</html>
* Connection #0 to host chinmayto.com left intact
```

Using below command (HTTPS) we can get the `200 OK` response.
```bash
$ curl -v https://chinmayto.com -k
* Host chinmayto.com:443 was resolved.
* IPv6: (none)
* IPv4: 18.214.175.186, 3.216.204.203 
*   Trying 18.214.175.186:443...      
* Connected to chinmayto.com (18.214.175.186) port 443  
* schannel: disabled automatic use of client certificate
* using HTTP/1.x
> GET / HTTP/1.1
> Host: chinmayto.com        
> User-Agent: curl/8.8.0     
> Accept: */*
>
* Request completely sent off
< HTTP/1.1 200 OK
< Date: Tue, 05 Aug 2025 10:19:07 GMT
< Content-Type: text/html; charset=utf-8
< Content-Length: 939
< Connection: keep-alive
< X-Powered-By: Express
< ETag: W/"3ab-8hgzRO4/VKFOziVvz3MVE2DQs1o"
< Strict-Transport-Security: max-age=31536000; includeSubDomains
<
<!DOCTYPE html>
<html>
<style>
body, html {
  height: 100%;
  margin: 0;
}

.bgimg {
  background-image: url('https://www.w3schools.com/w3images/forestbridge.jpg');
  height: 100%;
  background-position: center;
  background-size: cover;
  position: relative;
  color: white;
  font-family: "Courier New", Courier, monospace;
  font-size: 25px;
}

.topleft {
  position: absolute;
  top: 0;
  left: 16px;
}

.bottomleft {
  position: absolute;
  bottom: 0;
  left: 16px;
}

.middle {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  text-align: center;
}

hr {
  margin: auto;
  width: 40%;
}
</style>
<body>

<div class="bgimg">
  <div class="topleft">
    <p>ENVIRONMENT: DEV</p>
  </div>
  <div class="middle">
    <h1>Host/container name</h1>
    <hr>
    <p>deployment-nodejs-app-55555bc798-sshsh</p>
  </div>
  <div class="bottomleft">
    <p>Hello from Node!</p>
  </div>
</div>

</body>
</html>
* Connection #0 to host chinmayto.com left intact
```

We now have succesfully tested HTTPS connections using Self Signed Certs!!

### Conclusion: Why Use Self-Signed TLS?
While not suitable for production, self-signed TLS certificates are extremely useful for local development and testing, allowing you to:
1. Simulate real HTTPS behavior
2. Validate TLS configurations
3. Secure dev/test environments without external dependencies
4. Save cost on cert management for internal tools

### References
1. GitHub Repo: https://github.com/chinmayto/kubernetes-ingress-nginx/tree/main/Part_05

