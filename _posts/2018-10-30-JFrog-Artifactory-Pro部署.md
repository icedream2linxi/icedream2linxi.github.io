---
layout: post
date: 2018-10-30 15:26
title: JFrog Artifactory Pro 部署
categories: [Artifactory]
nocomments: false
---
# MariaDB 安装
Artifactory 支持多种数据库，这里选择 MariaDB。

官方下载页面有安装包的下载及安装说明：[https://downloads.mariadb.org/mariadb/10.3.10/](https://downloads.mariadb.org/mariadb/10.3.10/)

例如基于 yum 的自动安装：

在 `/etc/yum.repos.d/` 下添加 `MariaDB.repo`，内容为：
```ini
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```

接着再安装服务器和客户端：
```shell
sudo yum install MariaDB-server MariaDB-client
```

# Artifactory Pro 安装
在[管网](https://www.jfrog.com/artifactory/)上可以申请到 Pro 版的试用授权，并会提供下载地址。

包的安装见管网，已经讲的很清楚了：[https://jfrog.com/download-artifactory-pro/](https://jfrog.com/download-artifactory-pro/)

安装完之后，Artifactory 的安装目录位于`/opt/jfrog/artifactory`，后面说明都将基于这个目录。另外，它的数据及备份是保存于`/var/opt/jfrog/artifactory`；所以，如果有单独的用于保存数据的分区，要记得把这个目录符号链接到数据分区。

`misc/db/createdb/createdb_mariadb.sql`用于创建 artifactory 数据库及用户。里面的密码虽然使用的是默认的`password`，但没关系，Artifactory 会自动将该用户的密码改成高复杂度密码。

接着将`misc/db/mariadb.properties`文件复制到`etc`目录，并改名为`db.properties`。注意，这里的`etc`不是根目录下的`etc`，而是位于安装目录，如果不存在`etc`目录，则自行新建。

启动 Artifactory：

CentOS: `sudo /etc/init.d/artifactory start`

Ubuntu: `sudo service artifactory start`

管理员初始密码为：`password`

# 针对 docker 的修改
默认的配置是不能用于 docker 的。
操作步骤如下：
1. 以管理身份登录 Artifactory，并打开`HTTP Settings`。
2. `Docker Access Method`改为`Port`。
3. `Server Provider`改为`Nginx`。
4. 其他设置，看着改。一定要勾选`Use HTTPS`，因为 docker 会自动转到 HTTPS；SSL 证书生成可以参考[用于 Web 服务器的 SSL 证书生成]({{ site.url }}/blog/2018/10/30/用于Web服务器的SSL证书生成)。
5. 以上设置好之后，点`Save`。
6. 点`Download`，下载 Nginx 的配置文件。
7. 在配置文件中增加`rewrite ^/(v1|v2)/(.*) /artifactory/api/docker/docker/$1/$2;`。
8. 将配置文件复制到`/etc/nginx/conf.d/`下。
9. 重启 Nginx。