# HAProxy on Railway

HAProxy is a high-performance open-source load balancer and reverse proxy used to distribute traffic across backend services. It helps improve availability, route HTTP/TCP traffic, handle failover, and provide a reliable entry point for web applications, APIs, microservices, and internal services.

This repository is designed for Railway deployment with a default working HAProxy configuration. You can deploy it with zero configuration, then customize the routing rules later through GitHub, Railway Console, Railway CLI, or a persistent Railway Volume.

## Deploy on Railway

Click the button below to deploy this HAProxy template to Railway with zero configuration:

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/haproxy?referralCode=asepsp&utm_medium=integration&utm_source=template&utm_campaign=generic)

After deployment, HAProxy starts with the default configuration included in the image.

## Features

* HAProxy reverse proxy and load balancer
* Zero-config first deployment
* Default landing response to avoid server-down state
* Optional persistent custom config via Railway Volume
* Supports HTTP and TCP proxying
* Supports backend health checks
* Supports Railway private networking
* Suitable for APIs, web apps, microservices, and internal services

## Common Use Cases

* Reverse proxy for web apps, APIs, and internal services
* Load balancing across multiple backend instances
* Routing requests by domain, path, port, or service type
* Improving reliability with backend health checks and failover
* Central traffic entry point for microservices
* HTTP and TCP proxying for self-hosted applications

## Project Structure

```txt
.
├── Dockerfile
├── docker-entrypoint.sh
├── haproxy.cfg
└── README.md
```

## Configuration Behavior

This project supports two HAProxy configuration paths:

| Config Path                          | Purpose                                               |
| ------------------------------------ | ----------------------------------------------------- |
| `/usr/local/etc/haproxy/haproxy.cfg` | Default config included in the image                  |
| `/data/haproxy.cfg`                  | Optional persistent custom config from Railway Volume |

By default, HAProxy uses:

```txt
/usr/local/etc/haproxy/haproxy.cfg
```

If a Railway Volume is attached and this file exists:

```txt
/data/haproxy.cfg
```

the container automatically uses `/data/haproxy.cfg` instead of the default image configuration.

Startup behavior:

```txt
/data/haproxy.cfg exists     -> use /data/haproxy.cfg
/data/haproxy.cfg not found  -> use /usr/local/etc/haproxy/haproxy.cfg
```

This makes the template work immediately after deployment while still allowing persistent custom routing rules.

## Default HAProxy Config

The default configuration is stored in:

```txt
haproxy.cfg
```

During build, it is copied into the image as:

```txt
/usr/local/etc/haproxy/haproxy.cfg
```

The default config returns a simple HTTP 200 response so the service looks healthy immediately after deployment.

Example default response:

```txt
HAProxy is running on Railway. Edit haproxy.cfg to proxy your backend services.
```

## Custom Configuration with Railway Volume

To use a persistent custom config, attach a Railway Volume mounted at:

```txt
/data
```

Then create or update:

```txt
/data/haproxy.cfg
```

After editing the config, validate it:

```sh
haproxy -c -f /data/haproxy.cfg
```

Then restart or redeploy the Railway service.

HAProxy does not automatically reload config changes just because the file was edited.

## Update Config via Railway Console

Open your HAProxy service in Railway, then open the **Console** tab.

View the default config:

```sh
cat /usr/local/etc/haproxy/haproxy.cfg
```

Copy the default config into the Railway Volume:

```sh
cp /usr/local/etc/haproxy/haproxy.cfg /data/haproxy.cfg
```

Edit the custom config:

```sh
vi /data/haproxy.cfg
```

If `vi` is unavailable, overwrite the file manually:

```sh
cat > /data/haproxy.cfg <<'EOF'
global
    maxconn 4096
    log stdout format raw local0
    log stdout format raw local1 notice
    user root
    chroot /

defaults
    log     global
    mode    http
    option  httplog
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend main
    bind *:80
    http-request return status 200 content-type text/plain string "Custom HAProxy config from /data is running."

listen stats
    bind *:8404
    stats enable
    stats admin if TRUE
    stats uri /stats

EOF
```

Validate the config:

```sh
haproxy -c -f /data/haproxy.cfg
```

Then restart or redeploy the service from Railway.

## Update Config via Railway CLI

Install and authenticate Railway CLI:

```sh
railway login
railway link
```

Open an interactive shell inside the deployed service:

```sh
railway ssh
```

Copy the default config into the persistent volume:

```sh
cp /usr/local/etc/haproxy/haproxy.cfg /data/haproxy.cfg
```

Edit the custom config:

```sh
vi /data/haproxy.cfg
```

Validate it:

```sh
haproxy -c -f /data/haproxy.cfg
```

Exit the shell:

```sh
exit
```

Restart the service:

```sh
railway restart
```

Use redeploy if you want to trigger a new deployment:

```sh
railway redeploy
```

## Update Config via GitHub

Use this workflow if you want to manage HAProxy changes through GitHub and let Railway redeploy after every push.

1. Fork this repository.
2. Clone your fork locally:

```sh
git clone https://github.com/YOUR_USERNAME/haproxy.git
cd haproxy
```

3. Edit the default HAProxy config:

```txt
haproxy.cfg
```

4. Validate locally if HAProxy is installed:

```sh
haproxy -c -f haproxy.cfg
```

5. Commit and push your changes:

```sh
git add .
git commit -m "Customize HAProxy configuration"
git push origin main
```

6. In Railway, connect the service source repo to your fork if it is not already linked.
7. Future pushes to your fork can trigger automatic redeployments.

Important: GitHub changes update the default image config. If `/data/haproxy.cfg` exists, HAProxy will still use `/data/haproxy.cfg` instead of the Git-based default config.

To use the GitHub config again, remove the custom volume config:

```sh
rm /data/haproxy.cfg
```

Then restart or redeploy the service.

## Example Backend Configuration

Example backend for one Railway service:

```haproxy
backend app_backend
    balance roundrobin
    server app1 your-service.railway.internal:3000 check
```

Example backend for multiple Railway services:

```haproxy
backend app_backend
    balance roundrobin
    server app1 app-1.railway.internal:3000 check
    server app2 app-2.railway.internal:3000 check
```

Example frontend using the backend:

```haproxy
frontend main
    bind *:80
    default_backend app_backend
```

Replace the service names and ports with your actual Railway service private domains and internal ports.

## Roll Back to Default Config

If your custom config breaks or you want to return to the default image config, remove:

```sh
rm /data/haproxy.cfg
```

Then restart the service.

On the next startup, HAProxy falls back to:

```txt
/usr/local/etc/haproxy/haproxy.cfg
```

## Local Docker Usage

Build the image locally:

```sh
docker build -t railway-haproxy .
```

Run it locally:

```sh
docker run --rm -p 8080:80 railway-haproxy
```

Open:

```txt
http://localhost:8080
```

Validate the config inside the container:

```sh
docker run --rm railway-haproxy haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
```

## Important Notes

* Editing `haproxy.cfg` does not reload HAProxy automatically.
* Always validate the config before restarting the service.
* Use `/data/haproxy.cfg` for persistent custom configuration.
* Use `/usr/local/etc/haproxy/haproxy.cfg` as the default image configuration.
* If `/data/haproxy.cfg` exists, it takes priority over the default config.
* If `/data/haproxy.cfg` does not exist, the default image config is used.
* If the last line of `haproxy.cfg` is missing a newline, HAProxy may fail with a `Missing LF on last line` error.

## License

This project is provided as a deployment template for self-hosting HAProxy on Railway.
