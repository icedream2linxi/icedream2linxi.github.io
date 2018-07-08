---
layout: post
date: 2018-07-08 19:07
title: Windows 下编译 Tensorflow C++ API v1.8 Debug 版动态库
categories: [Tensorflow, Windows, C++]
nocomments: false
---
在前一篇文章《[Windows 下编译 Tensorflow C++ API v1.8 Release 版动态库]({{ site.url }}/blog/2018/07/08/Windows下编译Tensorflow-C++-API-v1.8-Release版动态库)》介绍了 Release 版的编译，但按这个去编译 Debug 版是不行的，有坑啊！

在编译到最后，生成 tensorflow.dll 的时候会报 `LNK1189：library limit of 65535 objects exceeded` 错误。

这个问题是因为 tensorflow.dll 导出的函数太多，超过了 65535 这个限制；置于为什么有这个限制，可以参考[^1]。

知道问题所在，就相对好办了；再看看 [TensorFlow C++ Reference](https://www.tensorflow.org/api_docs/cc/)，根本不该导出超过 65535 个函数啊！那一定导出了不该导出的函数，想办法不让他们被导出应该就可以了。

再看 `tensorflow\contrib\cmake\tools\create_def_file.py` 文件，里面就做了哪些该被导出，哪些不该被导出的事。

修改 tensorflow\contrib\cmake\tools\create_def_file.py 中的 EXCLUDE_RE 变量。修改为：

~~~python
EXCLUDE_RE = re.compile(r"RTTI|deleting destructor|::internal::|::`anonymous namespace'::|<lambda_[0-9a-z]+>|"
                        r"std::_Vector_iterator<|std::_Vector_const_iterator<|std::_Vector_alloc<|"
                        r"std::_Deque_iterator<|std::_Deque_alloc<|"
                        r"std::_Tree_iterator<|std::_Tree_const_iterator<|std::_Tree_unchecked_const_iterator<|std::_Tree_comp_alloc<|std::_Tree_node<|"
                        r"std::_List_iterator<|std::_List_const_iterator<|std::_List_unchecked_const_iterator<|std::_List_alloc<|"
                        r"std::_Iterator012<|std::_Compressed_pair<"
)
~~~

修改后，再类似 Release 的方式编译 Debug 版就可以了。

***
[^1]: [Fix msvc 65535 symbol limit in .lib files (LNK1189)](https://developercommunity.visualstudio.com/content/problem/220174/fix-msvc-65535-symbol-limit-in-lib-files-lnk1189.html)