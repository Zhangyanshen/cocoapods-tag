
module Pod
  class Command
    class Tag < Command
      class SpecPush < Tag

        self.summary = '上传 podspec 到 spec 仓库，自动跳过 xcodebuild 编译校验'

        self.description = <<-DESC
        #{self.summary}
        DESC

        self.arguments = [
          CLAide::Argument.new('REPO', true ),
          CLAide::Argument.new('NAME.podspec', true )
        ]

        def initialize(argv)
          @repo = argv.shift_argument
          @podspec = argv.shift_argument
          super
        end

        def run
          require 'cocoapods-tag/native/validator'

          unless @repo
            raise Informative, "请输入spec repo"
          end
          unless @podspec
            raise Informative, "请输入要上传的podspec"
          end
          UI.title "推送`#{@podspec}`到`#{@repo}`仓库".yellow do
            argvs = [
              @repo,
              @podspec,
              '--allow-warnings'
            ]
            begin
              push = Pod::Command::Repo::Push.new(CLAide::ARGV.new(argvs))
              push.validate!
              push.run
            rescue Pod::StandardError => e
              @error = e
              print "推送`#{@podspec}`到`#{@repo}`仓库失败！#{e}".red
            end
          end
        end

      end
    end
  end
end