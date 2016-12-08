#!/bin/sh
docker build --no-cache -t $DOCKER_REGISTRY_PRD/$CI_PROJECT_NAME .
docker images --no-trunc --all --quiet --filter="dangling=true" | xargs --no-run-if-empty docker rmi
docker push $DOCKER_REGISTRY_PRD/$CI_PROJECT_NAME
cd /opt/rancher-compose/
rm -rf $CI_PROJECT_NAME
mkdir $CI_PROJECT_NAME
cd $CI_PROJECT_NAME
echo "$CI_PROJECT_NAME:" > docker.yml
echo "  labels:" >> docker.yml
echo -e "    io.rancher.container.pull_image:\talways" >> docker.yml
echo -e "  tty:\ttrue" >> docker.yml
echo -e "  image:\t$DOCKER_REGISTRY_PRD/$CI_PROJECT_NAME" >> docker.yml
echo -e "  stdin_open:\ttrue" >> docker.yml
echo "$CI_PROJECT_NAME:" > rancher.yml
echo -e "  scale:\t$CONTAINER_SCALE" >> rancher.yml
../rancher-compose -f docker.yml -r rancher.yml -p $CI_PROJECT_NAME up --force-upgrade --batch-size 1 --interval "30000" -d --confirm-upgrade

