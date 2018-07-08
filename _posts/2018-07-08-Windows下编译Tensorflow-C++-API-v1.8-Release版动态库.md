---
layout: post
date: 2018-07-08 16:47
title: Windows 下编译 Tensorflow C++ API v1.8 Release 版动态库
categories: [Tensorflow, Windows, C++]
nocomments: false
---
我的目标是将编译好的动态库用于推导，因此，编译过程中所涉及的编译选项，能关闭的都将其关闭，尽量减少依赖。

从 [Tensorflow 官方 Github](https://github.com/tensorflow/tensorflow) 下载或 checkout 出 v1.8 版代码。

另外，我用到的工具 [CMake v3.11.4](https://cmake.org/download/)、[CUDA v9.0](https://developer.nvidia.com/cuda-90-download-archive)、[cuDNN v7.0.5](https://developer.nvidia.com/rdp/cudnn-archive) 及 Visual Studio 2015 Update 3。

在编译文件存放目录执行以下 CMake 命令来生成 Visual Studio 2015 项目文件：
~~~batch
cmake "${SOURCE_PATH}/tensorflow/contrib/cmake" ^
      -T "host=x64" ^
      -G "Visual Studio 14 2015 Win64" ^
      -Dtensorflow_ENABLE_SSL_SUPPORT=OFF ^
      -Dtensorflow_ENABLE_GRPC_SUPPORT=OFF ^
      -Dtensorflow_ENABLE_HDFS_SUPPORT=OFF ^
      -Dtensorflow_ENABLE_JEMALLOC_SUPPORT=OFF ^
      -Dtensorflow_BUILD_CC_EXAMPLE=OFF ^
      -Dtensorflow_BUILD_CC_TESTS=OFF ^
      -Dtensorflow_BUILD_PYTHON_TESTS=OFF ^
      -Dtensorflow_OPTIMIZE_FOR_NATIVE_ARCH=ON ^
      -Dtensorflow_WIN_CPU_SIMD_OPTIONS=/arch:AVX ^
      -Dtensorflow_BUILD_SHARED_LIB=ON ^
      -Dtensorflow_ENABLE_GPU=ON ^
      "-DCUDNN_HOME=%CUDA_PATH_V9_0%" ^
      -Dtensorflow_BUILD_PYTHON_BINDINGS=OFF ^
      "-DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}"
~~~
`${SOURCE_PATH}` 替换为 Tensorflow v1.8 的源代码路径。

`%CUDA_PATH_V9_0%` 这个环境变量对应为 CUDA v9.0 的安装目录；该环境变量在 CUDA v9.0 安装时被自动设置。

`${INSTALL_DIR}` 替换为你希望最后生成 lib、dll 文件及头文件的存放目录。

**不着急执行上述命令，因为有坑需要先进行修改。**

> 提示找不到 cpp_shape_inference.pb.h 文件。

在文件在 tensorflow_BUILD_PYTHON_BINDINGS=ON 时会被生成，因此，我们模仿下，在 =OFF 时也进行生成就 OK 了。
修改 `${SOURCE_PATH}/tensorflow/contrib/cmake/tf_c.cmake` 文件。

将

```cmake
add_library(tf_c_python_api OBJECT
  "${tensorflow_source_dir}/tensorflow/c/python_api.cc"
  "${tensorflow_source_dir}/tensorflow/c/python_api.h"
)
```

修改为

```cmake
function(RELATIVE_PROTOBUF_GENERATE_CPP SRCS HDRS ROOT_DIR)
  if(NOT ARGN)
    message(SEND_ERROR "Error: RELATIVE_PROTOBUF_GENERATE_CPP() called without any proto files")
    return()
  endif()

  set(${SRCS})
  set(${HDRS})
  foreach(FIL ${ARGN})
    set(ABS_FIL ${ROOT_DIR}/${FIL})
    get_filename_component(FIL_WE ${FIL} NAME_WE)
    get_filename_component(FIL_DIR ${ABS_FIL} PATH)
    file(RELATIVE_PATH REL_DIR ${ROOT_DIR} ${FIL_DIR})

    list(APPEND ${SRCS} "${CMAKE_CURRENT_BINARY_DIR}/${REL_DIR}/${FIL_WE}.pb.cc")
    list(APPEND ${HDRS} "${CMAKE_CURRENT_BINARY_DIR}/${REL_DIR}/${FIL_WE}.pb.h")

    add_custom_command(
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${REL_DIR}/${FIL_WE}.pb.cc"
             "${CMAKE_CURRENT_BINARY_DIR}/${REL_DIR}/${FIL_WE}.pb.h"
      COMMAND  ${PROTOBUF_PROTOC_EXECUTABLE}
      ARGS --cpp_out  ${CMAKE_CURRENT_BINARY_DIR} -I ${ROOT_DIR} ${ABS_FIL} -I ${PROTOBUF_INCLUDE_DIRS}
      DEPENDS ${ABS_FIL} protobuf
      COMMENT "Running C++ protocol buffer compiler on ${FIL}"
      VERBATIM )
  endforeach()

  set_source_files_properties(${${SRCS}} ${${HDRS}} PROPERTIES GENERATED TRUE)
  set(${SRCS} ${${SRCS}} PARENT_SCOPE)
  set(${HDRS} ${${HDRS}} PARENT_SCOPE)
endfunction()

if (NOT tensorflow_BUILD_PYTHON_BINDINGS)
  set(tf_python_protos_cc_srcs tensorflow/python/framework/cpp_shape_inference.proto)
  RELATIVE_PROTOBUF_GENERATE_CPP(PROTO_SRCS PROTO_HDRS
    ${tensorflow_source_dir} ${tf_python_protos_cc_srcs}
  )

  add_library(tf_c_python_api OBJECT
    ${PROTO_SRCS} ${PROTO_HDRS}
    "${tensorflow_source_dir}/tensorflow/c/python_api.cc"
    "${tensorflow_source_dir}/tensorflow/c/python_api.h"
  )
else()
  add_library(tf_c_python_api OBJECT
    "${tensorflow_source_dir}/tensorflow/c/python_api.cc"
    "${tensorflow_source_dir}/tensorflow/c/python_api.h"
  )
endif()
```

经过上述修改后再执行 CMake 命令来生成 Visual Studio 2015 项目文件。

接下打开 tensorflow.sln ，并编译 INSTALL 项目。或直接用命令进行编译：
~~~batch
msbuild INSTALL.vcxproj /t:build /p:configuration=Release /p:platform=x64 /m
~~~

这里还有个**坑**，如果你的内存不够，会提示 Faltal Error "compiler is out of heap space"。我试过，12 GB 内存会有此提示，32 GB 内存不会有此提示。

该问题是项目多进程编译引起的多编译进程叠加占用内存过高，单个进程不高，不过有时单个也会达到 6 GB。

其中占用内存最大的是编译 tf_core_kernels 的时候，因此，我们可以单独修改该项目的设置，该项目的 Properties -> C/C++ General -> Multi-processor Compilation 设置为 No。

另外，有个小**坑**，因为看一眼就知道被墙了，被墙的是 libpng-1.2.53.tar.gz 文件，该文件我们可以提前从 sourceforge 下好放编译目录下的 downloads 目录下。[libpng-1.2.53.tar.gz 下载链接](https://sourceforge.net/projects/libpng/files/libpng12/older-releases/1.2.53/libpng-1.2.53.tar.gz/download)。

好了，接下去愉快的编译吧！不过编译时间有点长，我 i7 处理器花了 5 个多小时。