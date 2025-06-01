sudo docker service rm dokploy dokploy-traefik dokploy-postgres dokploy-redis &&
  sudo docker volume rm -f dokploy-postgres-database redis-data-volume &&
  sudo docker swarm leave --force &&
  sudo docker network rm -f dokploy-network &&
  sudo docker rm -f dokploy-traefik &&
  sudo rm -rf /etc/dokploy
