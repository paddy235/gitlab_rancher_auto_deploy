#!/bin/sh
docker build --no-cache -t $DOCKER_REGISTRY_DEV/$CI_PROJECT_NAME .
docker images --no-trunc --all --quiet --filter="dangling=true" | xargs --no-run-if-empty docker rmi
docker push $DOCKER_REGISTRY_DEV/$CI_PROJECT_NAME
cd /home/gitlab-runner/rancher-compose/
rm -rf $CI_PROJECT_NAME
mkdir $CI_PROJECT_NAME
cd $CI_PROJECT_NAME
echo "version: '2'
services:
  $CI_PROJECT_NAME:
    image: $DOCKER_REGISTRY_DEV/$CI_PROJECT_NAME
    stdin_open: true
    tty: true
    labels:
      io.rancher.container.pull_image: always
      io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$CI_PROJECT_NAME/$CI_PROJECT_NAME" > docker.yml
echo "version: '2'
services:
  $CI_PROJECT_NAME:
    scale: $CONTAINER_SCALE" > rancher.yml
../rancher-compose --access-key $RANCHER_ACCESS_KEY_DEV --secret-key $RANCHER_SECRET_KEY_DEV -f docker.yml -r rancher.yml -p $CI_PROJECT_NAME up --force-upgrade --batch-size 1 --interval "5000" -d --confirm-upgrade