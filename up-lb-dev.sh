#!/bin/sh
cd /opt/rancher-compose/lb
rm -rf $CI_PROJECT_NAME
mkdir $CI_PROJECT_NAME
cd $CI_PROJECT_NAME
echo -e "lb-$CI_PROJECT_NAME:" > LBdocker.yml
echo -e "  ports:" >> LBdocker.yml
echo -e "  - $EXPORT_LB_PORT:$CONTAINER_SERVICE_PORT" >> LBdocker.yml
echo -e "  labels:" >> LBdocker.yml
echo -e "    io.rancher.scheduler.affinity:host_label:\tlb=true" >> LBdocker.yml
echo -e "  tty:\ttrue" >> LBdocker.yml
echo -e "  image:\trancher/load-balancer-service" >> LBdocker.yml
echo -e "  links:" >> LBdocker.yml
echo -e "  - $CI_PROJECT_NAME:$CI_PROJECT_NAME" >> LBdocker.yml
echo -e "  stdin_open:\ttrue" >> LBdocker.yml
echo -e "lb-$CI_PROJECT_NAME:" >> LBrancher.yml
echo -e "  scale:\t1" >> LBrancher.yml
echo -e "  load_balancer_config:" >> LBrancher.yml
echo -e "    haproxy_config:\t{}" >> LBrancher.yml
echo -e "  health_check:" >> LBrancher.yml
echo -e "    port:\t42" >> LBrancher.yml
echo -e "    interval:\t2000" >> LBrancher.yml
echo -e "    unhealthy_threshold:\t3" >> LBrancher.yml
echo -e "    healthy_threshold:\t2" >> LBrancher.yml
echo -e "    response_timeout:\t2000" >> LBrancher.yml
../../rancher-compose -f LBdocker.yml -r LBrancher.yml -p $CI_PROJECT_NAME up --force-upgrade --batch-size 1 --interval "30000" -d --confirm-upgrade

