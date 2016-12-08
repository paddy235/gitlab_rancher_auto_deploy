# gitlab_rancher_auto_deploy
##简介
用搭建一个基于gitlab代码版本,自动在rancher上用docker部署应用的平台。

PS:以下均使用centos7虚拟机搭建。
##Step1 搭建gitlab ce
PS：gitlab消耗内存，推荐分配2GB以上内存使用，否则页面卡。
+ 下载安装可参考官方文档：
[https://about.gitlab.com/downloads/#centos7](https://about.gitlab.com/downloads/#centos7)
+ 官方文档底部有针对国内用户的清华镜像地址：
[https://mirror.tuna.tsinghua.edu.cn/help/gitlab-ce/](https://mirror.tuna.tsinghua.edu.cn/help/gitlab-ce/)
+ 安装完成后，修改/etc/gitlab/gitlab.rb文件，修改external_url 'http://192.168.33.226' (本样例gitlab安装于192.168.33.226）此地址为git路径的域名，默认为localhost
+ 安装后到gitlab的bin目录执行sudo gitlab-ctl reconfigure启动
+ 启动后直接访问80端口即可看到gitlab注册页——注册账号——新建项目——上传代码

