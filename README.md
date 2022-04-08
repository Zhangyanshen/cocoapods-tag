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

