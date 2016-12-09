# gitlab_rancher_auto_deploy
##简介
用搭建一个基于gitlab代码版本,自动在rancher上用docker部署应用的平台。
>以下均使用centos7虚拟机搭建，虚拟机之间为局域网，网络互通。

##Step1 搭建gitlab ce
>gitlab消耗内存，推荐分配2GB以上内存使用，否则页面卡。

+ 下载安装可参考[官方文档](https://about.gitlab.com/downloads/#centos7)
+ 官方文档底部有针对国内用户的[清华镜像地址](https://mirror.tuna.tsinghua.edu.cn/help/gitlab-ce/)
+ 安装完成后，修改/etc/gitlab/gitlab.rb文件，修改``external_url 'http://192.168.33.226'`` (本样例gitlab安装于192.168.33.226）此地址为git路径的域名，默认为localhost
+ 安装后到gitlab的bin目录执行``sudo gitlab-ctl reconfigure``启动
+ 启动后直接访问80端口即可看到gitlab注册页——注册账号——新建项目——上传代码

##Step2 安装gitlab runner
>runner可与gitlab机器不同,内存推荐至少1GB，硬盘多分配以防项目过多导致磁盘满。

+ 安装参考[官方文档](https://docs.gitlab.com/runner/install/linux-manually.html)
+ 本样例registry时采用shell，若想使用docker需自建环境镜像。
+ 安装后可在gitlab用机器root账号登录访问http://192.168.33.226/admin/runners 查看runner信息。(本样例runner安装于192.168.33.225)

##Step3 搭建docker registry私有镜像库
+ 安装docker registry，需先安装docker,参考[官方文档](https://docs.docker.com/engine/installation/linux/centos/)
由于docker官方镜像库docker hub网络原因，推荐国内用户使用[daocloud镜像加速器](https://www.daocloud.io/mirror.html)
+ docker registry安装参考[官方文档](https://docs.docker.com/registry/)
+ 由于docker registry 拉取镜像时只支持https地址，需在拉取镜像服务器修改/usr/lib/systemd/system/docker.service文件
``ExecStart=/usr/bin/dockerd --insecure-registry 192.168.33.211:5000``（本样例私有镜像库安装在192.168.33.211）
+ 添加后执行``systemctl daemon-reload``重启docker，即可忽略拉取镜像时https报错。

##Step4 安装rancher
+ 先安装docker，参考step3，后执行``docker run -d --restart=unless-stopped -p 8080:8080 rancher/server``即可
+ 访问8080端口可直接进入控制页面，右下角可切换语言
+ 基础架构-主机-添加主机，将用于部署的应用机器加入到rancher内管理。（注意执行脚本前关闭防火墙，时间同步）
+ 将一台或者多台机器添加标签lb=true，充当服务访问入口（对应up-lb脚本内的调度规则，也可自定义修改）
+ 系统管理-高可用，按照说明配置可将rancher落地到数据库
+ API，添加环境API，将弹出的key和秘钥存储，后续rancher compose需要用到。

##Step5 下载rancher compose
+ 根据step4上安装的docker版本（控制台左下角点击版本号，查看Rancher Compose版本）
+ 访问[官方文档](https://github.com/rancher/rancher-compose/releases)找到对应版本的rancher compose下载
+ 将下载的rancher compose脚本放在gitlab runner机器的/opt/rancher-compose/目录下（自定义需修改项目deploy-common-***.sh文件）

##Step6 gitlab runner 服务器配置环境变量
+ 在gitlab runner机器上修改/etc/profile文件，在最后添加：

  ```
    export RANCHER_URL=http://192.168.33.221:8080/
    export RANCHER_ACCESS_KEY=8FFBE33462AE5F245A5F
    export RANCHER_SECRET_KEY=MpXXvnLKamrv8uhfkBz7KNbFx1axdNv3EncXsZG9
    export DOCKER_REGISTRY_DEV=192.168.33.211:5000
    export DOCKER_REGISTRY_PRD=***.***.***.***:5000
  ```
  >RANCHER_URL为rancher地址
  >RANCHER_ACCESS_KEY,RANCHER_SECRET_KEY为step4中的API环境秘钥
  >DOCKER_REGISTRY_DEV为私有镜像库地址，dev为开发环境，prd为生产环境，分别对应不同脚本。
  
+ 执行脚本mkdir /opt/rancher-compose/lb创建文件夹，用于存储不同项目lb的compose文件
+ 将项目内的deploy-common-***.sh,up-lb-***.sh四个文件放在/opt/deploy-shell文件夹下

##Step7 项目根目录添加.gitlab-ci.yml文件
+ 本项目有maven+jre8+jar；maven+tomcat+jre8+war；nodejs的.yml文件模板，可参考使用。
+ 提交项目代码到gitlab，目前定义master分支为prd环境，执行prd脚本以及上传到prd私有镜像库。test分支为dev环境，执行dev脚本，使用dev镜像库
+ 登录gitlab，进入项目页面-Pipelines可以看到每次提交版本的记录，进入点击deploy自动部署，up_lb为启动/重启负载均衡。
+ Environment标签内有dev prd两个环境的部署记录，可以点击Rollback按钮自动回滚。

#最后的一些说明
+ rancher环境还可新增一套环境，主机不同即可
+ gitlab runner可启动多个，并发执行多个项目部署
+ docker registry 推荐在不同环境分别部署。