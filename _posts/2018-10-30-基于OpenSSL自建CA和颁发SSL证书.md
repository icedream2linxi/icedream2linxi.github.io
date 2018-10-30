---
layout: post
date: 2018-10-30 14:31
title: (转,改) 基于 OpenSSL 自建 CA 和颁发 SSL 证书
categories: [SSL]
nocomments: false
---
转载并修改自：[http://seanlook.com/2015/01/18/openssl-self-sign-ca/](http://seanlook.com/2015/01/18/openssl-self-sign-ca/)

关于 SSL/TLS 介绍见文章 [SSL/TLS原理详解](http://seanlook.com/2015/01/07/tls-ssl)。

关于证书授权中心CA以及数字证书等概念，请移步 [OpenSSL 与 SSL 数字证书概念贴](http://seanlook.com/2015/01/15/openssl-certificate-encryption) 。

openssl 是一个开源程序的套件、这个套件有三个部分组成：一是`libcryto`，这是一个具有通用功能的加密库，里面实现了众多的加密库；二是`libssl`，这个是实现 ssl 机制的，它是用于实现 TLS/SSL 的功能；三是 openssl，是个多功能命令行工具，它可以实现加密解密，甚至还可以当 CA 来用，可以让你创建证书、吊销证书。

默认情况 ubuntu 和 CentOS 上都已安装好 openssl。CentOS 6.x 上有关 ssl 证书的目录结构：
```shell
/etc/pki/CA/
            newcerts    存放CA签署（颁发）过的数字证书（证书备份目录）
            private     用于存放CA的私钥
            crl         吊销的证书

/etc/pki/tls/
             cert.pem    软链接到certs/ca-bundle.crt
             certs/      该服务器上的证书存放目录，可以房子自己的证书和内置证书
             ca-bundle.crt    内置信任的证书
             private    证书密钥存放目录
             openssl.cnf    openssl的CA主配置文件
```

<!-- more -->

# 颁发证书

## 修改 CA 的一些配置文件
CA 要给别人颁发证书，首先自己得有一个作为根证书，我们得在一切工作之前修改好CA 的配置文件、序列号、索引等等。

`vi /etc/pki/tls/openssl.cnf`：
```shell
...
[ CA_default ]

dir             = /etc/pki/CA           # Where everything is kept
certs           = $dir/certs            # Where the issued certs are kept
crl_dir         = $dir/crl              # Where the issued crl are kept
database        = $dir/index.txt        # database index file.
#unique_subject = no                    # Set to 'no' to allow creation of
                                        # several ctificates with same subject.
new_certs_dir   = $dir/newcerts         # default place for new certs.

certificate     = $dir/cacert.pem       # The CA certificate
serial          = $dir/serial           # The current serial number
crlnumber       = $dir/crlnumber        # the current crl number
                                        # must be commented out to leave a V1 CRL
crl             = $dir/crl.pem          # The current CRL
private_key     = $dir/private/cakey.pem # The private key
RANDFILE        = $dir/private/.rand    # private random number file
...
default_days    = 3650                  # how long to certify for
...
# For the CA policy
[ policy_match ]
countryName             = match
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional
...
[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
countryName_default             = CN
countryName_min                 = 2
countryName_max                 = 2

stateOrProvinceName             = State or Province Name (full name)
stateOrProvinceName_default     = GD
...
[ req_distinguished_name ] # 部分主要是颁证时一些默认的值，可以不动
```

一定要注意`[ policy_match ]`中的设定的匹配规则，是有可能因为证书使用的工具不一样，导致即使设置了 csr 中看起来有相同的 countryName, stateOrProvinceName 等，但在最终生成证书时依然报错：
```shell
Using configuration from /usr/lib/ssl/openssl.cnf
Check that the request matches the signature
Signature ok
The stateOrProvinceName field needed to be the same in the
CA certificate (GuangDong) and the request (GuangDong)
```

`touch index.txt serial`：

在 CA 目录下创建两个初始文件
```shell
# touch index.txt serial
# echo 01 > serial
```

## 生成根密钥
```shell
# cd /etc/pki/CA/
# openssl genrsa -out private/cakey.pem 2048
```
为了安全起见，修改cakey.pem私钥文件权限为600或400，也可以使用子 shell 生成`( umask 077; openssl genrsa -out private/cakey.pem 2048 )`，下面不再重复。

## 生成根证书
使用 req 命令生成自签证书：
```shell
# openssl req -new -x509 -key private/cakey.pem -out cacert.pem
```
会提示输入一些内容，因为是私有的，所以可以随便输入（之前修改的 openssl.cnf 会在这里呈现），最好记住能与后面保持一致。上面的自签证书`cacert.pem`应该生成在`/etc/pki/CA`下。

## 为我们的 nginx web 服务器生成 ssl 密钥
以上都是在 CA 服务器上做的操作，而且只需进行一次，现在转到 nginx 服务器上执行：
```shell
# cd /etc/nginx/ssl
# openssl genrsa -out nginx.key 2048
```
这里测试的时候 CA 中心与要申请证书的服务器是同一个。

## 为 nginx 生成证书签署请求
```shell
# openssl req -new -key nginx.key -out nginx.csr
...
Country Name (2 letter code) [AU]:CN
State or Province Name (full name) [Some-State]:GD
Locality Name (eg, city) []:SZ
Organization Name (eg, company) [Internet Widgits Pty Ltd]:COMPANY
Organizational Unit Name (eg, section) []:IT_SECTION
Common Name (e.g. server FQDN or YOUR name) []:your.domain.com
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
...
```
同样会提示输入一些内容，其它随便，除了`Commone Name`一定要是你要授予证书的服务器域名或主机名，challenge password 不填。

## 私有 CA 根据请求来签署证书
接下来要把上一步生成的证书请求 csr 文件，发到 CA 服务器上，在 CA 上执行：
```shell
# openssl ca -in nginx.csr -out nginx.crt

另外在极少数情况下，上面的命令生成的证书不能识别，试试下面的命令：
# openssl x509 -req -in server.csr -CA /etc/pki/CA/cacert.pem -CAkey /etc/pki/CA/private/cakey.pem -CAcreateserial -out server.crt
```
上面签发过程其实默认使用了`-cert cacert.pem -keyfile cakey.pem`，这两个文件就是前两步生成的位于`/etc/pki/CA`下的根密钥和根证书。将生成的 crt 证书发回 nginx 服务器使用。

到此我们已经拥有了建立ssl安全连接所需要的所有文件，并且服务器的 crt 和 key 都位于配置的目录下，剩下的是如何使用证书的问题。

# 使用ssl证书

## 一般浏览器
浏览器作为客户端去访问 https 加密的服务器，一般不用去手动做其他设置，如https://www.google.com.hk，这是因为 Chrome、FireFox、Safari、IE 等浏览器已经内置了大部分常用的 CA 的根证书，但自建 CA 的根证书就不再浏览器的信任列表中，访问时会提示如下：

IE浏览器

![IE浏览器](/assets/2018-10-30/openssl-https-browser-ie.png)

谷歌浏览器

![谷歌浏览器](/assets/2018-10-30/openssl-https-browser.png)

安装网站证书后（同时也有信任的根证书），地址栏一般会显示绿色小锁

![12306](/assets/2018-10-30/openssl-https-12306.png)

证书信息

![cert](/assets/2018-10-30/openssl-https-browser-cert.png)

导入证书到浏览器的方法：[http://cnzhx.net/blog/self-signed-certificate-as-trusted-root-ca-in-windows/](http://cnzhx.net/blog/self-signed-certificate-as-trusted-root-ca-in-windows/)

## 为 Linux 系统添加根证书
这一步不是必须的，一般出现在开发测试环境中，而且具体的应用程序应该提供添加证书的方法。

`curl`工具可以在 Linux 上模拟发送请求，但当它去访问 https 加密网站时就会提示如下信息：
```shell
# curl https://sean:sean@registry.domain.com:8000/
curl: (60) Peer certificate cannot be authenticated with known CA certificates
More details here: http://curl.haxx.se/docs/sslcerts.html
curl performs SSL certificate verification by default, using a "bundle"
 of Certificate Authority (CA) public keys (CA certs). If the default
 bundle file isn't adequate, you can specify an alternate file
 using the --cacert option.
If this HTTPS server uses a certificate signed by a CA represented in
 the bundle, the certificate verification probably failed due to a
 problem with the certificate (it might be expired, or the name might
 not match the domain name in the URL).
If you'd like to turn off curl's verification of the certificate, use
 the -k (or --insecure) option.
 ```
 提示上面的信息说明 curl 在 Linux 的证书信任集里没有找到根证书，你可以使用`curl --insecure`来不验证证书的可靠性，这只能保证数据是加密传输的但无法保证对方是我们要访问的服务。使用`curl --cacert cacert.pem`可以手动指定根证书路径。我们也可以把根证书添加到系统（CentOS 5,6）默认的 bundle：
 ```shell
 # cp /etc/pki/tls/certs/ca-bundle.crt{,.bak}    备份以防出错
# cat /etc/pki/CA/cacert.pem >> /etc/pki/tls/certs/ca-bundle.crt

# curl https://sean:sean@registry.domain.com:8000
"docker-registry server (dev) (v0.8.1)"
```

## nginx
在nginx配置文件（可能是`/etc/nginx/sites-available/default`）的 server 指令下添加：
```shell
ssl on;
ssl_certificate /etc/nginx/ssl/nginx.crt;
ssl_certificate_key /etc/nginx/ssl/nginx.key;
```
同时注意 server_name 与证书申请时的 Common Name 要相同，打开 443 端口。当然关于 web 服务器加密还有其他配置内容，如只对部 URL 加密，对 URL 重定向实现强制 https 访问，请参考其他资料。

# 关于证书申请
注意，如果对于一般的应用，管理员只需生成“证书请求”（后缀大多为 .csr），它包含你的名字和公钥，然后把这份请求交给诸如 verisign 等有 CA 服务公司（当然，连同几百美金），你的证书请求经验证后，CA 用它的私钥签名，形成正式的证书发还给你。管理员再在 web server 上导入这个证书就行了。如果你不想花那笔钱，或者想了解一下原理，可以自己做 CA。从 CA 的角度讲，你需要 CA 的私钥和公钥。从想要证书的服务器角度将，需要把服务器的证书请求交给 CA。

如果你要自己做 CA，别忘了客户端需要导入 CA 的证书（CA 的证书是自签名的，导入它意味着你“信任”这个 CA 签署的证书）。而商业CA的一般不用，因为它们已经内置在你的浏览器中了。

# 参考
[CentOS6.5下openssl加密解密及CA自签颁发证书详解](http://blog.csdn.net/napolunyishi/article/details/42425827)

[基于 OpenSSL 的 CA 建立及证书签发](http://www.cnblogs.com/popsuper1982/p/3843772.html)

[openssl建立证书，非常详细配置ssl+apache](http://blog.51yip.com/apachenginx/958.html)

[The Secure Sockets Layer and Transport Layer Security](http://www.ibm.com/developerworks/library/ws-ssl-security/)