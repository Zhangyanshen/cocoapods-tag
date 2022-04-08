require 'cocoapods-tag/tag'

module Pod
  class Command
    class Tag < Command
      class Auto < Tag
        include Pod

        self.summary = '创建 tag 并 push 到远端仓库，同时可以上传 podspec 到 spec repo'

        self.description = <<-DESC
#{self.summary}

`TAG`: tag号【必填】\n
`COMMIT_MSG`: commit信息【必填】\n
`TAG_MSG`: tag信息【可选，默认为"v[tag号]"，比如：tag是"0.0.1"，则tag信息是"v0.0.1"】\n

eg:\n
1.使用默认tag信息\n
pod tag 0.1.7 "修改podspec版本号为0.1.7"\n
2.使用自定义tag信息\n
pod tag 0.1.7 "修改podspec版本号为0.1.7" "版本0.1.7"\n
3.推送podspec到spec repo\n
pod tag 0.1.7 "修改podspec版本号为0.1.7" "版本0.1.7" --spec-repo=xxx\n
4.跳过耗时校验\n
pod tag 0.1.7 "修改podspec版本号为0.1.7" "版本0.1.7" --spec-repo=xxx --quick
DESC

        self.arguments = [
          CLAide::Argument.new('TAG', true ),
          CLAide::Argument.new('COMMIT_MSG', true),
          CLAide::Argument.new('TAG_MSG', false)
        ]

        def self.options
          [
            ['--spec-repo=SPECREPO', 'podspec 推送到的 spec repo ，可以通过`pod repo list`查看'],
            ['--quick', '跳过一些耗时校验，如：远端仓库是否已经有该 tag ']
          ].concat(super)
        end

        def initialize(argv)
          @tag = argv.shift_argument
          @commit_msg = argv.shift_argument
          @tag_msg = argv.shift_argument
          @spec_repo = argv.option('spec-repo', nil)
          @quick = argv.flag?('quick', false)
          super
        end

        def run
          tag = Pod::Tag.new(@tag, @commit_msg, @tag_msg, @spec_repo, @quick)
          tag.create
        end

      end
    end
  end
end
