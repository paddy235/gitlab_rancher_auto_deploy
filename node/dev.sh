#!/bin/sh
echo "FROM base-node
COPY ./ /opt
CMD npm run node" > dockerfile
docker build --no-cache -t $DOCKER_REGISTRY_DEV/$CI_PROJECT_NAME .
docker images --no-trunc --all --quiet --filter="dangling=true" | xargs --no-run-if-empty docker rmi
docker push $DOCKER_REGISTRY_DEV/$CI_PROJECT_NAME
echo "version: '2'
services:
  $CI_PROJECT_NAME:
    image: $DOCKER_REGISTRY_DEV/$CI_PROJECT_NAME
    stdin_open: true
    volumes:
    - /opt/logs:/opt/logs
    ports:
    - $EXPORT_PORT:$CONTAINER_PORT/tcp
    tty: true
    labels:
      io.rancher.container.pull_image: always
      io.rancher.scheduler.affinity:container_label_ne: io.rancher.stack_service.name=node/$CI_PROJECT_NAME" > docker.yml
echo "version: '2'
services:
  $CI_PROJECT_NAME:
    scale: $CONTAINER_SCALE
    start_on_create: true
    health_check:
      response_timeout: 2000
      healthy_threshold: 2
      port: $CONTAINER_PORT
      unhealthy_threshold: 3
      initializing_timeout: 60000
      interval: 2000
      strategy: none
      request_line: GET "$HEALTH_CHECK_URL" "HTTP/1.0"
      reinitializing_timeout: 60000" > rancher.yml
/home/gitlab-runner/rancher-compose/rancher-compose --url $RANCHER_URL_DEV --access-key $RANCHER_ACCESS_KEY_DEV --secret-key $RANCHER_SECRET_KEY_DEV -f docker.yml -r rancher.yml -p node up --force-upgrade --batch-size 1 --interval "3000" -d --confirm-upgrade
