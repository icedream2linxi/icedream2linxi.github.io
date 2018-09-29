---
layout: post
date: 2018-09-29 09:21
title: Windows 下不污染环境安装 Rust 编译器
categories: [Rust]
nocomments: false
---
如果你用 CI (持续集成系统) 自动构建你的程序，又由于历史原因要使用不同版本的 Rust 编译，那么就不希望环境受污染，Docker 是一种不错的选择，这里提供另一种选择。

Rust 对 Windows 提供了 rustup-init.exe、xxx-pc-windows-msvc.msi、xxx-pc-windows-msvc.tar.gz 三种安装方式。rustup-init.exe 会自动安装到 `%USERPROFILE%\.cargo`，并配置了环境变量。xxx-pc-windows-msvc.msi 可以指定安装目录，但会自动配置环境变量、需要管理员身份运行、用命令行又不能指定安装路径。最后只有 xxx-pc-windows-msvc.tar.gz 是可行的。

xxx-pc-windows-msvc.tar.gz 是通过执行 `install.sh` 的 Shell 脚本来进行安装，因此，需要一个能执行 Shell 脚本的环境，可以选择 MSYS、Cygwin、WSL 等。执行 `install.sh` 时，通过 `--prefix` 参数设定安装目录。例如：

```shell
bash -c "./install.sh --prefix=/mnt/d/rust"
```

这样子安装就可以了，不会污染环境。

使用时，将安装目录下的 `bin` 目录设置到 `PATH` 环境变量中就可以了。