#!/bin/sh
cd /home/gitlab-runner/rancher-compose/lb
rm -rf $CI_PROJECT_NAME
mkdir $CI_PROJECT_NAME
cd $CI_PROJECT_NAME
echo "version: '2'
services:
  lb-$CI_PROJECT_NAME:
    image: rancher/lb-service-haproxy:v0.4.6
    ports:
    - $EXPORT_LB_PORT
    labels:
      io.rancher.scheduler.affinity:host_label: lb=true" > LBdocker.yml
echo "version: '2'
services:
  lb-$CI_PROJECT_NAME:
    scale: 2
    lb_config:
      port_rules:
      - service: $CI_PROJECT_NAME/$CI_PROJECT_NAME
        source_port: $EXPORT_LB_PORT
        target_port: $CONTAINER_SERVICE_PORT
    health_check:
      healthy_threshold: 2
      response_timeout: 2000
      port: 42
      unhealthy_threshold: 3
      interval: 2000" > LBrancher.yml
../../rancher-compose --access-key $RANCHER_ACCESS_KEY_PRD --secret-key $RANCHER_SECRET_KEY_PRD -f LBdocker.yml -r LBrancher.yml -p $CI_PROJECT_NAME up --force-upgrade --batch-size 1 --interval "30000" -d --confirm-upgrade