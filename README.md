# gitlab_rancher_auto_deploy
##简介
用搭建一个基于gitlab代码版本,自动在rancher上用docker部署应用的平台。

PS:以下均使用centos7虚拟机搭建，虚拟机之间为局域网，网络互通。
##Step1 搭建gitlab ce
PS：gitlab消耗内存，推荐分配2GB以上内存使用，否则页面卡。
+ 下载安装可参考[官方文档](https://about.gitlab.com/downloads/#centos7)
+ 官方文档底部有针对国内用户的[清华镜像地址](https://mirror.tuna.tsinghua.edu.cn/help/gitlab-ce/)
+ 安装完成后，修改/etc/gitlab/gitlab.rb文件，修改external_url 'http://192.168.33.226' (本样例gitlab安装于192.168.33.226）此地址为git路径的域名，默认为localhost
+ 安装后到gitlab的bin目录执行sudo gitlab-ctl reconfigure启动
+ 启动后直接访问80端口即可看到gitlab注册页——注册账号——新建项目——上传代码

##Step2 安装gitlab runner
PS：runner可与gitlab机器不同,内存推荐至少1GB，硬盘多分配以防项目过多导致磁盘满。
+ 安装参考[官方文档](https://docs.gitlab.com/runner/install/linux-manually.html)
+ 本样例registry时采用shell，若想使用docker需自建环境镜像。
+ 安装后可在gitlab用机器root账号登录访问http://192.168.33.226/admin/runners 查看runner信息。(本样例runner安装于192.168.33.225)

##Step3 搭建docker registry私有镜像库
+ docker registry 为docker镜像，需先安装docker,参考[官方文档](https://docs.docker.com/engine/installation/linux/centos/)
由于docker官方镜像库docker hub网络原因，推荐国内用户使用[daocloud镜像加速器](https://www.daocloud.io/mirror.html)
+ docker registry安装参考[官方文档](https://docs.docker.com/registry/)
+ 由于docker registry 拉取镜像时只支持https地址，需在拉取镜像服务器修改/usr/lib/systemd/system/docker.service文件
ExecStart=/usr/bin/dockerd **--insecure-registry 192.168.33.211:5000**（本样例私有镜像库安装在192.168.33.211）
添加后执行systemctl daemon-reload重启docker，即可忽略拉取镜像时https报错。

##Step4 安装rancher


##Step10 项目根目录添加.gitlab-ci.yml文件
+ 本项目有maven+jre8+jar/maven+tomcat+jre8+war/nodejs的.yml文件模板，可参考使用。