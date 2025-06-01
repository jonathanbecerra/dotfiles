#!/bin/bash

install_dokploy() {
  # Ensure script is run as root
  if [ "$(id -u)" != "0" ]; then
    echo "Error: This script must be run as root." >&2
    exit 1
  fi

  # Ensure we're on Linux, not macOS or inside a container
  if [ "$(uname)" = "Darwin" ]; then
    echo "Error: This script must be run on Linux." >&2
    exit 1
  fi
  if [ -f /.dockerenv ]; then
    echo "Error: This script must be run on a Linux host, not inside a container." >&2
    exit 1
  fi

  # Require exactly one argument: the Tailscale IP
  if [ -z "$1" ]; then
    echo "Usage: $0 <TAILSCALE_IP>" >&2
    echo "Example: $0 100.123.45.67" >&2
    exit 1
  fi
  advertise_addr="$1"
  echo "Using provided Tailscale IP as advertise address: $advertise_addr"

  # Check for any service already bound to port 80 or 443
  if ss -tulnp | grep -q ':80 '; then
    echo "Error: Something is already running on port 80." >&2
    exit 1
  fi
  if ss -tulnp | grep -q ':443 '; then
    echo "Error: Something is already running on port 443." >&2
    exit 1
  fi

  # Helper to verify existence of a command
  command_exists() {
    command -v "$@" >/dev/null 2>&1
  }

  # Install Docker if missing
  if command_exists docker; then
    echo "Docker already installed."
  else
    echo "Installing Docker..."
    curl -sSL https://get.docker.com | sh
  fi

  # If this node was previously part of a Swarm, leave it to start fresh
  docker swarm leave --force 2>/dev/null || true

  # Initialize Docker Swarm using the provided Tailnet IP
  docker swarm init --advertise-addr "$advertise_addr"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to initialize Docker Swarm." >&2
    exit 1
  fi
  echo "Swarm initialized with advertise address $advertise_addr."

  # Remove any old Dokploy network, then recreate it
  docker network rm -f dokploy-network 2>/dev/null || true
  docker network create --driver overlay --attachable dokploy-network
  echo "Created overlay network 'dokploy-network'."

  # Create directory for Dokploy configuration
  mkdir -p /etc/dokploy
  chmod 777 /etc/dokploy

  # Deploy Postgres service
  docker service create \
    --name dokploy-postgres \
    --constraint 'node.role==manager' \
    --network dokploy-network \
    --env POSTGRES_USER=dokploy \
    --env POSTGRES_DB=dokploy \
    --env POSTGRES_PASSWORD=amukds4wi9001583845717ad2 \
    --mount type=volume,source=dokploy-postgres-database,target=/var/lib/postgresql/data \
    postgres:16

  # Deploy Redis service
  docker service create \
    --name dokploy-redis \
    --constraint 'node.role==manager' \
    --network dokploy-network \
    --mount type=volume,source=redis-data-volume,target=/data \
    redis:7

  # Pre-pull images for Traefik and Dokploy
  docker pull traefik:v3.1.2
  docker pull dokploy/dokploy:latest

  # Deploy Dokploy service
  docker service create \
    --name dokploy \
    --replicas 1 \
    --network dokploy-network \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    --mount type=bind,source=/etc/dokploy,target=/etc/dokploy \
    --mount type=volume,source=dokploy-docker-config,target=/root/.docker \
    --update-parallelism 1 \
    --update-order stop-first \
    --constraint 'node.role == manager' \
    -e ADVERTISE_ADDR="$advertise_addr" \
    dokploy/dokploy:latest

  # Deploy Traefik as a standalone container (outside Swarm)
  docker run -d \
    --name dokploy-traefik \
    --network dokploy-network \
    --restart always \
    -v /etc/dokploy/traefik/traefik.yml:/etc/traefik/traefik.yml \
    -v /etc/dokploy/traefik/dynamic:/etc/dokploy/traefik/dynamic \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -p "$1":3000:3000 \ traefik:v3.1.2
  # -p 80:80/tcp \
  # -p 443:443/tcp \
  # -p 443:443/udp \

  # Color definitions for user-friendly output
  GREEN="\033[0;32m"
  YELLOW="\033[1;33m"
  BLUE="\033[0;34m"
  NC="\033[0m" # No Color

  # Format the provided IP for URL usage (IPv6 bracketed, IPv4 plain)
  format_ip_for_url() {
    local ip="$1"
    if echo "$ip" | grep -q ':'; then
      echo "[${ip}]"
    else
      echo "${ip}"
    fi
  }

  formatted_addr=$(format_ip_for_url "$advertise_addr")
  echo ""
  printf "${GREEN}Congratulations, Dokploy is installed!${NC}\n"
  printf "${BLUE}Wait 15 seconds for the services to spin up…${NC}\n"
  printf "${YELLOW}Visit http://${formatted_addr}:3000 to access the dashboard${NC}\n\n"
}

update_dokploy() {
  echo "Updating Dokploy…"

  # Pull the latest Dokploy image
  docker pull dokploy/dokploy:latest

  # Update the running Dokploy service
  docker service update --image dokploy/dokploy:latest dokploy

  echo "Dokploy has been updated to the latest version."
}

# Main script execution
if [ "$1" = "update" ]; then
  update_dokploy
else
  install_dokploy "$1"
fi
