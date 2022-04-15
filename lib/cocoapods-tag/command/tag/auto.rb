require 'cocoapods-tag/tag'

module Pod
  class Command
    class Tag < Command
      class Auto < Tag
        include Pod

        self.summary = '创建 tag 并 push 到远端仓库，同时可以上传 podspec 到 spec repo'

        self.description = <<-DESC
#{self.summary}

`VERSION`: podspec中的version字段，如果没有prefix和suffix，version与tag一样【必填】\n
`COMMIT_MSG`: commit信息【必填】\n
`TAG_MSG`: tag信息【可选，默认为"v[tag号]"，比如：tag是"0.0.1"，则tag信息是"v0.0.1"】\n

e.g.\n
1.使用默认tag信息\n
pod tag 0.1.7 "修改podspec版本号为0.1.7"\n
2.使用自定义tag信息\n
pod tag 0.1.7 "修改podspec版本号为0.1.7" "版本0.1.7"\n
3.推送podspec到spec repo\n
pod tag 0.1.7 "修改podspec版本号为0.1.7" "版本0.1.7" --spec-repo=xxx\n
4.跳过耗时校验\n
pod tag 0.1.7 "修改podspec版本号为0.1.7" "版本0.1.7" --quick\n
5.指定工作目录\n
pod tag 0.1.7 "修改podspec版本号为0.1.7" --work-dir=xxx\n
6.为tag指定前后缀\n
pod tag 0.1.7 "修改podspec版本号为0.1.7" --prefix="xxx" --suffix="xxx"\n
7.指定tag推送到的远端仓库\n
pod tag 0.1.7 "修改podspec版本号为0.1.7" --remote=xxx
DESC

        self.arguments = [
          CLAide::Argument.new('VERSION', true ),
          CLAide::Argument.new('COMMIT_MSG', true),
          CLAide::Argument.new('TAG_MSG', false)
        ]

        def self.options
          [
            ['--quick', '跳过一些耗时校验，如：远端仓库是否已经有该tag'],
            ['--skip-push-commit', '跳过推送commit到对应分支'],
            ['--remote=REMOTE', '指定tag推送到的远端仓库，可以通过`git remote -v`查看'],
            ['--spec-repo=SPECREPO', 'podspec推送到的repo，可以通过`pod repo list`查看'],
            ['--work-dir=WORKDIR', '执行命令的工作区'],
            ['--prefix=PREFIX', 'tag前缀'],
            ['--suffix=SUFFIX', 'tag后缀']
          ].concat(super)
        end

        def initialize(argv)
          @version = argv.shift_argument
          @commit_msg = argv.shift_argument
          @tag_msg = argv.shift_argument
          @quick = argv.flag?('quick', false)
          @skip_push_commit = argv.flag?('skip-push-commit', false)
          @remote = argv.option('remote', false)
          @spec_repo = argv.option('spec-repo', nil)
          @work_dir = argv.option('work-dir', nil)
          @prefix = argv.option('prefix', nil)
          @suffix = argv.option('suffix', nil)
          @tag = @version
          unless @prefix.nil?
            @tag = "#{@prefix}-#{@tag}"
          end
          unless @suffix.nil?
            @tag = "#{@tag}-#{@suffix}"
          end
          super
        end

        def run
          # 传入了工作目录
          unless @work_dir.nil?
            raise Informative, "不存在工作目录`#{@work_dir}`" unless File.exist?(@work_dir)
            Dir.chdir(@work_dir)
          end
          tag = Pod::Tag.new(@version, @tag, @commit_msg, @tag_msg, @spec_repo, @quick, @remote, @skip_push_commit)
          tag.create
        end

      end
    end
  end
end
