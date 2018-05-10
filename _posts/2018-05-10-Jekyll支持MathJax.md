---
layout: post
date: 2018-05-10 18:24
title: Jekyll 支持 MathJax
categories: [Jekyll, MathJax]
---
需要在页面中引入 MathJax 的 JavaScript 或 CSS 来渲染 $\LaTeX$[^1]，例如：
~~~ javascript
<script src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.0/MathJax.js?config=TeX-AMS-MML_HTMLorMML" type="text/javascript"></script>
~~~

默认 `\\(...\\)` 为行内数学公式，`$$...$$` 和 `\\[...\\]` 为独立显示公式。

常用的 `$...$` 并不是默认支持的，如果要支持，这需要在页面中加入以下代码[^2]：
~~~ javascript
MathJax.Hub.Config({
  tex2jax: {
    inlineMath: [ ['$','$'], ["\\(","\\)"] ],
});
~~~

经过以上设置后的示例：

`$a^2 + b^2 = c^2$` 显示为 $a^2 + b^2 = c^2$， `\\(a^2 + b^2 = c^2\\)` 显示为 \\(a^2 + b^2 = c^2\\)。

代码
~~~ latex
\\[ \mathbf{X} = \mathbf{Z} \mathbf{P^\mathsf{T}} \\]
~~~
显示为：

\\[ \mathbf{X} = \mathbf{Z} \mathbf{P^\mathsf{T}} \\]


代码
~~~ latex
$$ \mathbf{X}\_{n,p} = \mathbf{A}\_{n,k} \mathbf{B}\_{k,p} $$
~~~
显示为：

$$ \mathbf{X}\_{n,p} = \mathbf{A}\_{n,k} \mathbf{B}\_{k,p} $$

代码
~~~ latex
$$ 
\begin{aligned}
  & \phi(x,y) = \phi \left(\sum_{i=1}^n x_ie_i, \sum_{j=1}^n y_je_j \right)
  = \sum_{i=1}^n \sum_{j=1}^n x_i y_j \phi(e_i, e_j) = \\
  & (x_1, \ldots, x_n) \left( \begin{array}{ccc}
      \phi(e_1, e_1) & \cdots & \phi(e_1, e_n) \\
      \vdots & \ddots & \vdots \\
      \phi(e_n, e_1) & \cdots & \phi(e_n, e_n)
    \end{array} \right)
  \left( \begin{array}{c}
      y_1 \\
      \vdots \\
      y_n
    \end{array} \right)
\end{aligned}
$$
~~~
显示为：

$$ 
\begin{aligned}
  & \phi(x,y) = \phi \left(\sum_{i=1}^n x_ie_i, \sum_{j=1}^n y_je_j \right)
  = \sum_{i=1}^n \sum_{j=1}^n x_i y_j \phi(e_i, e_j) = \\
  & (x_1, \ldots, x_n) \left( \begin{array}{ccc}
      \phi(e_1, e_1) & \cdots & \phi(e_1, e_n) \\
      \vdots & \ddots & \vdots \\
      \phi(e_n, e_1) & \cdots & \phi(e_n, e_n)
    \end{array} \right)
  \left( \begin{array}{c}
      y_1 \\
      \vdots \\
      y_n
    \end{array} \right)
\end{aligned}
$$

不过有个 BUG，如果文档中有 `\begin{displaymath}...\end{displaymath}` 这样的代码，MathJax 会当公式处理，显示效果如下：
\begin{displaymath}...\end{displaymath}
建议以下写法：
~~~
`\begin{displaymath}...\end{displaymath}`
~~~

***
[^1]: [Jekyll Extras](https://jekyllrb.com/docs/extras/)
[^2]: [Loading and Configuring MathJax](http://docs.mathjax.org/en/latest/configuration.html#using-in-line-configuration-options)