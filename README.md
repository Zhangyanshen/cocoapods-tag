## 简介

`cocoapods-tag`是一个可以方便地帮助Pod库打tag的`CocoaPods`插件。

## 安装

```shell
$ gem install cocoapods-tag
```

## 使用

* 查看帮助

  ```shell
  $ pod tag --help
  $ pod tag auto --help
  ```

* 使用默认tag信息，如tag为“0.1.7”，那么tag信息为”v0.1.7“

  ```shell
  $ pod tag 0.1.7 "修改podspec版本号为0.1.7"
  ```

* 使用自定义tag信息

  ```shell
  $ pod tag 0.1.7 "修改podspec版本号为0.1.7" "版本0.1.7"
  ```

* 推送`podspec`到指定的`spec repo`

  ```shell
  $ pod tag 0.1.7 "修改podspec版本号为0.1.7" "版本0.1.7" --spec-repo=xxx
  ```

* 跳过耗时校验

  ```shell
  $ pod tag 0.1.7 "修改podspec版本号为0.1.7" "版本0.1.7" --spec-repo=xxx --quick
  ```

* 指定tag推送到的远端仓库（可以通过`git remote -v`查看）

  ```shell
  $ pod tag 0.1.7 "修改podspec版本号为0.1.7" "版本0.1.7" --remote=origin
  ```
  
* 指定工作目录（插件执行的目录）

  ```shell
  $ pod tag 0.1.7 "修改podspec版本号为0.1.7" --work-dir=xxx
  ```

* 为tag添加前后缀 **（前后缀与版本号中间会自动用`-`分隔，不需要手动添加）**

  以下面这行命令为例，`podspec`中的`version`为`0.1.7`，`source`字段中的`tag`为`mtxx-0.1.7-beta1`，最终推送到远端仓库的`tag`也是`mtxx-0.1.7-beta1`

  ```shell
  $ pod tag 0.1.7 "修改podspec版本号为0.1.7" --prefix="mtxx" --suffix="beta1"
  ```

* 单独推送`podspec`到指定`spec repo`

  ```shell
  $ pod tag spec-push REPO NAME.podspec
  ```

> 如有疑问，请使用`pod tag auto --help`查看帮助信息，里面有每个字段的解释

## 版本号

`CocoaPods`对版本号是有校验的，如果不符合规则当推送`podspec`到`spec repo`时会校验失败，具体校验正则如下：

```ruby
VERSION_PATTERN = '[0-9]+(?>\.[0-9a-zA-Z]+)*(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?'
ANCHORED_VERSION_PATTERN = /\A\s*(#{VERSION_PATTERN})?\s*\z/
```

大概解释一下就是：以`数字0-9`开头，中间可以包含`数字0-9`、`字母a-z A-Z`，特殊字符只能包含`.`和`-`，版本号前后可以有`0个或多个空格`

> 1. `cocoapods-tag`已经对版本号做了正则校验，不符合上面正则的版本号是无法通过的，这里写出来主要是为了提醒大家注意版本号的规范
> 2. 不建议版本号前后加空格
