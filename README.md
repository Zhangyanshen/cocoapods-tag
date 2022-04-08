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



