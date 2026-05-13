# vps-stack-mate

> A Bash CLI for deploying Docker Compose services on a VPS with NGINX reverse proxy and automatic Let's Encrypt SSL

## Contents

- [Getting Started](#getting-started)
  - [Clone the repository](#clone-the-repository)
  - [Make scripts executable](#make-scripts-executable)
  - [Generate the configuration files](#generate-the-configuration-files)
  - [Deploy the stack](#deploy-the-stack)
- [Adding services and domains](#adding-services-and-domains)
- [Commands](#commands)
- [License](#license)
- [Support](#support)

With just a few commands you'll have NGINX, SSL certificates, and your Docker services up and running on your VPS.

---

## Getting Started

### Clone the repository

Clone this repository on your VPS:

```sh
git clone git@github.com:parisikosto/vps-stack-mate.git
cd vps-stack-mate
```

### Make scripts executable

```sh
chmod +x mate.sh && chmod -R +x scripts/
```

### Generate the configuration files

```sh
./mate.sh generate-config-files
```

This creates two files:

- `.env` — service names and Certbot settings. You will be asked for your email address (used for SSL certificate expiry notifications).
- `domains.json` — the list of domains to deploy. Edit it with your real domains before deploying.

```sh
# Edit domains.json with your real domains
nano domains.json

# Format: a JSON array of domain strings
# ["yourdomain.com", "api.yourdomain.com"]
```

> **Before deploying**, make sure your domains have an A record pointing to your VPS IP. Let's Encrypt needs to reach your server on port 80 to verify ownership.

### Deploy the stack

```sh
sudo ./mate.sh deploy-stack
```

This will:

1. Start the NGINX and Certbot containers
2. Provision a Let's Encrypt SSL certificate for each domain
3. Write the NGINX configs and reload NGINX

---

## Adding services and domains

### Add a new service

Create a `docker-compose.override.yml` file in the repo root. Docker Compose automatically merges it with `docker-compose.yml` — no need to edit the base file.

```yaml
services:
  my-service:
    container_name: my-service
    image: my-image:latest
    restart: unless-stopped
```

### Add a custom nginx config

For each domain that should proxy to a service, create a file in `nginx/conf/` named after the domain:

```
nginx/conf/yourdomain.com.conf
```

Example with `proxy_pass`:

```nginx
server {
    listen 80;
    server_name yourdomain.com;
    server_tokens off;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name yourdomain.com;
    server_tokens off;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://my-service/;
    }
}
```

If no custom conf file exists for a domain, the default template is used (serves static files).

### Reload after changes

| Situation                        | Command                         |
| -------------------------------- | ------------------------------- |
| New domain that needs SSL        | `sudo ./mate.sh deploy-domains` |
| Changed an nginx conf file       | `sudo ./mate.sh reload-domains` |
| Updated a Docker image           | `./mate.sh reload-service`      |
| Added a new service + new domain | `sudo ./mate.sh reload-stack`   |
| Everything from scratch          | `sudo ./mate.sh deploy-stack`   |

---

## Commands

| Command                           | Description                                                          |
| --------------------------------- | -------------------------------------------------------------------- |
| `./mate.sh generate-env-file`     | Generate the `.env` file                                             |
| `./mate.sh generate-domains-file` | Generate the `domains.json` file                                     |
| `./mate.sh generate-config-files` | Generate both config files at once                                   |
| `sudo ./mate.sh deploy-domains`   | Provision SSL certs and write nginx configs                          |
| `sudo ./mate.sh deploy-services`  | Start the Docker Compose stack                                       |
| `sudo ./mate.sh deploy-stack`     | Full deploy: services + domains                                      |
| `sudo ./mate.sh reload-domains`   | Rebuild nginx configs and restart NGINX                              |
| `./mate.sh reload-service`        | Pull and recreate a single service                                   |
| `sudo ./mate.sh reload-stack`     | Redeploy all services and reload domains                             |
| `./mate.sh clean-stack`           | Remove generated files (certbot/, nginx/conf.d/, .env, domains.json) |
| `./mate.sh --help`                | Show the help message                                                |

---

## License

This repository is licensed under the [MIT License](https://opensource.org/licenses/MIT).

## Support

For support and questions, please open an issue in the repository or contact the author directly.
