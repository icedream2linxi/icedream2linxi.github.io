---
layout: post
date: 2018-07-18 10:05
title: restbed 自定义 Header 控制接口版本
categories: [restbed, Restful, C++]
nocomments: false
---
自定义 Header 方式控制 Restful 接口版本是一种常用的做法，restbed 可以通过过滤器来实现。

restbed 的过滤器有个设定，如果不存在相应的 Header，则自动使用第一个 handler。所以，则个设定可以用于默认版本；如果不想要默认版本，那可以将第一个 handler 设为错误处理函数，或添加个 Rule 来处理。

例子：

``` cpp
#include <memory>
#include <cstdlib>
#include <restbed>

using namespace std;
using namespace restbed;

void get_method_handler_v1(const shared_ptr<Session> session)
{
	const auto request = session->get_request();
	printf("%s\n", __FUNCTION__);
	session->close(OK, __FUNCTION__);
}

void get_method_handler_v2(const shared_ptr<Session> session)
{
	const auto request = session->get_request();
	printf("%s\n", __FUNCTION__);
	session->close(OK, __FUNCTION__);
}

void failed_filter_validation_handler(const shared_ptr<Session> session)
{
	session->close(400);
}

int main(const int, const char**)
{
	auto resource = make_shared<Resource>();
	resource->set_path("/resource");
	resource->set_failed_filter_validation_handler(&failed_filter_validation_handler);
	resource->set_method_handler("GET", { { "X-Api-Version", "v1" } }, &get_method_handler_v1);
	resource->set_method_handler("GET", { { "X-Api-Version", "v2" } }, &get_method_handler_v2);

	auto settings = make_shared<Settings>();
	settings->set_port(1984);
	settings->set_default_header("Connection", "close");

	Service service;
	service.publish(resource);
	service.start(settings);

	return EXIT_SUCCESS;
}
```
<!-- more -->

测试：

命令：`curl -w'\n' -v -X GET http://localhost:1984/resource`

结果：

```
Note: Unnecessary use of -X or --request, GET is already inferred.
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 1984 (#0)
> GET /resource HTTP/1.1
> Host: localhost:1984
> User-Agent: curl/7.47.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Connection: close
<
* Closing connection 0
get_method_handler_v1
```

命令：`curl -w'\n' -v -X GET -H "X-Api-Version: v1" http://localhost:1984/resource`

结果：

```
Note: Unnecessary use of -X or --request, GET is already inferred.
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 1984 (#0)
> GET /resource HTTP/1.1
> Host: localhost:1984
> User-Agent: curl/7.47.0
> Accept: */*
> X-Api-Version: v1
>
< HTTP/1.1 200 OK
< Connection: close
<
* Closing connection 0
get_method_handler_v1
```

命令：`curl -w'\n' -v -X GET -H "X-Api-Version: v2" http://localhost:1984/resource`

结果：

```
Note: Unnecessary use of -X or --request, GET is already inferred.
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 1984 (#0)
> GET /resource HTTP/1.1
> Host: localhost:1984
> User-Agent: curl/7.47.0
> Accept: */*
> X-Api-Version: v2
>
< HTTP/1.1 200 OK
< Connection: close
<
* Closing connection 0
get_method_handler_v2
```

命令：`curl -w'\n' -v -X GET -H "X-Api-Version: v3" http://localhost:1984/resource`

结果：

```
Note: Unnecessary use of -X or --request, GET is already inferred.
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 1984 (#0)
> GET /resource HTTP/1.1
> Host: localhost:1984
> User-Agent: curl/7.47.0
> Accept: */*
> X-Api-Version: v3
>
< HTTP/1.1 400 Bad Request
< Connection: close
<
* Closing connection 0

```