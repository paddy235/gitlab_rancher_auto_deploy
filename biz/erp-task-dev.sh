#!/bin/sh
cd erp-task/target
echo "FROM base-openjdk
COPY erp-task.jar /opt
CMD java -Dfile.encoding=UTF-8 -Duser.timezone=Asia/Shanghai -jar /opt/erp-task.jar" > dockerfile
docker build --no-cache -t $DOCKER_REGISTRY_DEV/erp-task .
docker images --no-trunc --all --quiet --filter="dangling=true" | xargs --no-run-if-empty docker rmi
docker push $DOCKER_REGISTRY_DEV/erp-task
echo "version: '2'
services:
  erp-task:
    image: $DOCKER_REGISTRY_DEV/erp-task
    stdin_open: true
    tty: true
    volumes:
    - /opt/logs:/opt/logs
    labels:
      io.rancher.container.pull_image: always
      io.rancher.scheduler.affinity:container_label_ne: io.rancher.stack_service.name=biz/erp-task" > docker.yml
echo "version: '2'
services:
  erp-task:
    scale: 1
    start_on_create: true" > rancher.yml
/home/gitlab-runner/rancher-compose/rancher-compose --url $RANCHER_URL_DEV --access-key $RANCHER_ACCESS_KEY_DEV --secret-key $RANCHER_SECRET_KEY_DEV -f docker.yml -r rancher.yml -p biz up --force-upgrade --batch-size 1 --interval "3000" -d --confirm-upgrade
