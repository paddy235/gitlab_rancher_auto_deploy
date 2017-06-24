#!/bin/sh
cd /$CI_PROJECT_DIR/$PACKAGE_PATH
echo "FROM base-openjdk
COPY $PACKAGE_NAME /opt
COPY lib /opt/lib
CMD java -Dfile.encoding=UTF-8 -Duser.timezone=Asia/Shanghai -cp /opt/lib/*:/opt/$PACKAGE_NAME chaos.Consumer" > dockerfile
docker build --no-cache -t $DOCKER_REGISTRY_PRD_JF/$CI_PROJECT_NAME .
docker images --no-trunc --all --quiet --filter="dangling=true" | xargs --no-run-if-empty docker rmi
docker push $DOCKER_REGISTRY_PRD_JF/$CI_PROJECT_NAME
echo "version: '2'
services:
  $CI_PROJECT_NAME:
    image: $DOCKER_REGISTRY_PRD_JF/$CI_PROJECT_NAME
    stdin_open: true
    volumes:
    - /opt/logs:/opt/logs
    tty: true
    labels:
      io.rancher.container.pull_image: always
      io.rancher.scheduler.affinity:container_label_ne: io.rancher.stack_service.name=biz/$CI_PROJECT_NAME" > docker.yml
echo "version: '2'
services:
  $CI_PROJECT_NAME:
    scale: 1
    start_on_create: true" > rancher.yml
/home/gitlab-runner/rancher-compose/rancher-compose --url $RANCHER_URL_PRD_JF --access-key $RANCHER_ACCESS_KEY_PRD_JF --secret-key $RANCHER_SECRET_KEY_PRD_JF -f docker.yml -r rancher.yml -p biz up --force-upgrade --batch-size 1 --interval "30000" -d --confirm-upgrade
