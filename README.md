# gitlab-ci + rancher

## 简介
> 搭建一个基于gitlab-ci,一键在rancher上部署基于容器的应用的持续集成平台。

## 关于应用架构的一些说明
> 由于应用较少且都是微服务，所以使用的是rancher默认的cattle容器编排策略，依赖cattle自己建立的容器间相互通信，容器外隔离的网络机制。
> rancher自带dns可以实现带负载均衡的服务间的相互调用，而且重建容器不受影响
> rancher里有一些社区封装好的catalog，点击即用，非常实用，例如kafka，elasticsearch,influxdb,prometheus等。

## 搭建步骤
> 以下均使用centos7虚拟机搭建，虚拟机之间为局域网，网络互通。

### Step1 搭建gitlab ce
> gitlab消耗内存，推荐分配2GB以上内存使用，否则页面卡。

+ 下载安装可参考[官方文档](https://about.gitlab.com/downloads/#centos7)
+ 官方文档底部有针对国内用户的[清华镜像地址](https://mirror.tuna.tsinghua.edu.cn/help/gitlab-ce/)
+ 安装完成后，修改/etc/gitlab/gitlab.rb文件，修改``external_url 'http://192.168.33.226'`` (本样例gitlab安装于192.168.33.226）此地址为git路径的域名，默认为localhost
+ 安装后到gitlab的bin目录执行``sudo gitlab-ctl reconfigure``启动
+ 启动后直接访问80端口即可看到gitlab注册页——注册账号——新建项目——上传代码

### Step2 安装gitlab runner
> runner可与gitlab机器不同,内存推荐至少1GB，硬盘多分配以防项目过多导致磁盘满。

+ 安装参考[官方文档](https://docs.gitlab.com/runner/install/linux-manually.html)
+ 本样例registry时采用shell，若想使用docker需自建环境镜像。
+ 安装后可在gitlab用机器root账号登录访问http://192.168.33.226/admin/runners 查看runner信息。(本样例runner安装于192.168.33.225)

### Step3 搭建docker registry私有镜像库

+ 安装docker registry，需先安装docker,参考[官方文档](https://docs.docker.com/engine/installation/linux/centos/)
由于docker官方镜像库docker hub网络原因，推荐国内用户使用[daocloud镜像加速器](https://www.daocloud.io/mirror.html)
+ docker registry安装参考[官方文档](https://docs.docker.com/registry/)
+ 由于docker registry 拉取镜像时只支持https地址，需在拉取镜像服务器修改/usr/lib/systemd/system/docker.service文件
``ExecStart=/usr/bin/dockerd --insecure-registry 192.168.33.211:5000``（本样例私有镜像库安装在192.168.33.211）
+ 添加后执行``systemctl daemon-reload``重启docker，即可忽略拉取镜像时https报错。

### Step4 安装rancher及新建主机

+ 先安装docker，参考step3，后执行``docker run -d --restart=unless-stopped -p 8080:8080 rancher/server``即可
+ 访问8080端口可直接进入控制页面，右下角可切换语言
+ 基础架构-主机-添加主机，将用于部署的应用机器加入到rancher内管理。（注意执行脚本前关闭防火墙，时间同步）
+ 将一台或者多台机器添加标签lb=true，充当服务访问入口（对应up-lb脚本内的调度规则，也可自定义修改）
+ 系统管理-高可用，按照说明配置可将rancher落地到数据库
+ API，添加环境API，将弹出的key和秘钥存储，后续rancher compose需要用到。

### Step5 下载rancher compose

+ 根据step4上安装的docker版本（控制台左下角点击版本号，查看Rancher Compose版本）
+ 访问[官方文档](https://github.com/rancher/rancher-compose/releases)找到对应版本的rancher compose下载
+ 将下载的rancher compose脚本放在gitlab runner机器的任意目录下（样例放在/opt/rancher-compose/，脚本在启动容器的时候会用到）

### Step6 gitlab runner 服务器配置环境变量

+ 在gitlab runner机器上修改/etc/profile文件，添加一些全局的变量，给执行脚本使用，便于修改，以下为样例

  ```
    export RANCHER_URL=http://192.168.33.221:8080/
    export RANCHER_ACCESS_KEY=8FFBE33462AE5F245A5F
    export RANCHER_SECRET_KEY=MpXXvnLKamrv8uhfkBz7KNbFx1axdNv3EncXsZG9
    export DOCKER_REGISTRY_DEV=192.168.33.211:5000
    export DOCKER_REGISTRY_PRD=***.***.***.***:5000
  ```
  > RANCHER_URL为rancher地址
  > RANCHER_ACCESS_KEY,RANCHER_SECRET_KEY为step4中的API环境秘钥 
  > DOCKER_REGISTRY_DEV为私有镜像库地址，dev为开发环境，prd为生产环境，分别对应不同脚本。


### Step7 项目根目录添加.gitlab-ci.yml文件

+ 在应用项目代码根目录新建.gitlab-ci.yml，具体语法参考[官方文档](https://docs.gitlab.com/ee/ci/yaml/README.html),以下为样例

```
variables:
  #包名
  PACKAGE_NAME: "cart-service.jar"
  #包路径(相对于项目根目录,以/开头)
  PACKAGE_PATH: "/target"
  #启动服务的容器数量
  CONTAINER_SCALE: "2"
  #容器内部访问端口号
  CONTAINER_PORT: "8080"
  #健康监测地址(相对路径,以/开头)
  HEALTH_CHECK_URL: "/cart-service/cart/status"
stages:
  - deploy

#dev environment
deploy_dev:
  stage: deploy
  only:
    - test
  environment:
    name: dev
  when: manual
  script:
    # package
    - mvn clean package -Dmaven.test.skip=true
    # run common deploy shell
    - sh /home/gitlab-runner/deploy-shell-2.0/biz/dev.sh

#prd environment
deploy_prd_jf:
  stage: deploy
  only:
    - prd-jf
  environment:
    name: prd-jf
  when: manual
  script:
    # package
    - mvn clean package -Dmaven.test.skip=true
    # run common deploy shell
    - sh /home/gitlab-runner/deploy-shell-2.0/biz/prd-jf.sh
```

+ 提交项目代码到gitlab，目前定义master分支为prd环境，执行prd脚本以及上传到prd私有镜像库。test分支为dev环境，执行dev脚本，使用dev镜像库
+ 登录gitlab，进入项目页面-Pipelines可以看到每次提交版本的记录，进入点击deploy自动部署。
+ Environment标签内有dev prd两个环境的部署记录，可以点击Rollback按钮自动回滚,也可以点击相应git版本的代码再次发布达到回滚效果。

# 最后的一些说明

+ rancher环境还可新增一套环境，主机不同即可
+ gitlab runner可启动多个，并发执行多个项目部署
+ docker registry 推荐在不同环境分别部署。
+ 有不懂的可以联系QQ793271105