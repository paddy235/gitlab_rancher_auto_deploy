#!/bin/sh
cd /$CI_PROJECT_DIR/$PACKAGE_PATH
echo "FROM base-openjdk
COPY $PACKAGE_NAME /opt
CMD java -Dfile.encoding=UTF-8 -Duser.timezone=Asia/Shanghai -jar /opt/$PACKAGE_NAME" > dockerfile
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
      io.rancher.scheduler.affinity:container_label_ne: io.rancher.stack_service.name=$CI_PROJECT_NAME/$CI_PROJECT_NAME" > docker.yml
echo "version: '2'
services:
  $CI_PROJECT_NAME:
    scale: 1
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
/home/gitlab-runner/rancher-compose/rancher-compose --url $RANCHER_URL_PRD_JF --access-key $RANCHER_ACCESS_KEY_PRD_JF --secret-key $RANCHER_SECRET_KEY_PRD_JF -f docker.yml -r rancher.yml -p $CI_PROJECT_NAME up --force-upgrade --batch-size 1 --interval "30000" -d --confirm-upgrade
