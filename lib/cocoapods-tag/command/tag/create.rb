require 'cocoapods-tag/helper/asker'

module Pod
  class Command
    class Tag < Command
      class Create < Tag
        include Pod

        GITHUB_DOMAIN = "github.com".freeze
        GIT_REPO = ".git".freeze
        PODSPEC_EXT = %w[podspec podspec.json].freeze

        self.summary = '【问答的方式】创建 tag 并 push 到远端仓库，同时可以上传 podspec 到 spec repo'

        self.description = <<-DESC
        #{self.summary}
        DESC

        def initialize(argv)
          super
        end

        def run
          require 'cocoapods-tag/native/validator'

          # 欢迎提示
          asker.welcome_message
          # 检查本地 git 仓库
          check_git_repo?
          # 加载 podspec
          load_podspec
          # 提示用户输入 version
          ask_version
          # 提示用户输入前缀
          ask_prefix
          # 提示用户输入后缀
          ask_suffix
          # 提示用户输入 commit msg 和 tag msg
          ask_commit_tag_msg
          # 询问用户推送到哪个远端仓库
          ask_remote
          # 提示用户确认
          ask_sure
          # 修改 podspec
          modify_podspec
          # 推送 tag 到远端
          git_tag_push
          # 询问用户是否推送 podspec 到 spec 仓库
          ask_push_podspec_to_repo
          # 结束提示
          asker.done_message if @error.nil?
        end

        private

        # 加载 podspec
        def load_podspec
          unless check_podspec_exist?
            raise Informative, "`#{Dir.pwd}`不存在podspec"
          end
          @spec = Specification.from_file(@podspecs.first)
          raise Informative, "加载`#{@podspecs.first}`失败！" if @spec.nil?
          @spec_hash = @spec.to_hash
          source = @spec_hash['source']
          # 目前只处理 git 这种形式
          unless source['git']
            raise Informative, "目前只能处理`git`这种形式"
          end
          # git字段为空
          if source['git'] && source['git'].strip == ''
            raise Informative, "source中git字段不能为空"
          end
          # 判断 source 中是否包含 github.com
          if source['git'] && source['git'].include?(GITHUB_DOMAIN)
            message = "\n`#{@podspecs.first}`的source中包含`#{GITHUB_DOMAIN}`，请确认是否正确？"
            answer = asker.ask(message, true, nil, { '1' => '正确✅', '2' => '错误❌' })
            if answer == '2'
              exit("\n程序终止\n")
            end
          end
          # 修改前校验一次 podspec
          lint_podspec("\n修改前校验`#{@podspecs.first}`：\n")
        end

        # 检查 git repo
        def check_git_repo?
          print "检查git仓库：\n".yellow

          git_repo = File.join(Dir.pwd, GIT_REPO)
          raise Informative, "`#{Dir.pwd}`不存在git仓库，请先使用`git init`初始化git仓库" unless File.exist?(git_repo)

          remotes = `git remote`.split("\n")
          raise Informative, "本地git仓库没有与远端仓库关联，请先使用`git remote add`关联远端仓库" if remotes.empty?

          local_commit = `git rev-parse HEAD`.chomp
          remote_commit = `git ls-remote --head`.split("\t")[0]
          raise Informative, "本地git仓库没有与远端同步，请先执行`git pull`或`git fetch + git rebase`拉取最新代码" unless local_commit == remote_commit
        end

        # 提示用户输入版本号
        def ask_version
          question = "\n请输入版本号（用于修改`podspec`中的`version`）："
          pre_answer = @spec_hash['version']
          regx = {
            "tip" => "版本号中间必须有'.'且每一位只支持数字，如：0.1、1.1.2等",
            "pattern" => /^(\d+\.)+\d+$/
          }
          @version = asker.ask(question, true, pre_answer, nil, regx)
        end

        # 提示用户输入前缀
        def ask_prefix
          question = "\n请输入tag前缀："
          @prefix = asker.ask(question)
          print "无前缀\n" if @prefix.size == 0
        end

        # 提示用户输入后缀
        def ask_suffix
          question = "\n请输入tag后缀："
          @suffix = asker.ask(question)
          print "无后缀\n" if @suffix.size == 0
        end

        # 提示用户输入 commit msg 和 tag msg
        def ask_commit_tag_msg
          @commit_msg = asker.ask("\n请输入commit信息：", true)
          @tag_msg = asker.ask("\n请输入tag信息：", true)
        end

        # 询问用户推送到哪个远端仓库
        def ask_remote
          remotes = `git remote`.split("\n")
          @remote = remotes[0] unless remotes.empty?
          if remotes.size > 1
            count = 0
            selections = {}
            remotes.map do |remote|
              count += 1
              selections["#{count}"] = remote
            end
            key = asker.ask("\n请选择推送到的远端仓库：", true, nil, selections)
            @remote = remotes["#{key}".to_i]
          end
        end

        # 提示用户确认信息
        def ask_sure
          @tag = "#{@prefix}#{@version}#{@suffix}"
          question = <<-Q

请确认以下信息：
——————————————————————————————————————
|tag: #{@tag}
|version: #{@version}
|commit_msg: #{@commit_msg}
|tag_msg: #{@tag_msg}
|current_branch: #{current_branch}
|remote: #{@remote}
——————————————————————————————————————
          Q
          selections = {'1'=> '确认', '2'=> '取消'}
          answer = asker.ask(question, true, nil, selections)
          if answer == 2
            exit("\n程序终止\n")
          end
        end

        # 修改podspec
        def modify_podspec
          if @podspecs.nil? || @podspecs.empty?
            return
          end
          podspec = @podspecs.first
          file = File.join(Dir.pwd, "#{podspec}")
          # 匹配文件名后缀
          if podspec =~ /.podspec$/
            modify_podspec_ruby(file)
          elsif podspec =~ /.podspec.json$/
            modify_podspec_json(file)
          end
          # 修改完再次校验 podspec
          lint_podspec("\n修改后校验`#{@podspecs.first}`：\n")
        end

        # 修改 *.podspec
        def modify_podspec_ruby(file)
          org_source = @spec_hash['source']
          des_source = "{ :git => '#{org_source['git']}', :tag => '#{@tag}' }"
          File.open(file, 'r') do |f|
            lines = []
            f.each_line do |line|
              if line =~ /(^\s*.+\.version\s*=\s*).*/
                line = line.sub(/(^\s*.+\.version\s*=\s*).*/, "#{$1}'#{@version}'")
              end
              if line =~ /(^\s*.+\.source\s*=\s*).*/
                line = line.sub(/(^\s*.+\.source\s*=\s*).*/, "#{$1}#{des_source}")
              end
              lines << line
            end
            File.open(file, 'w') do |f|
              f.write(lines.join(""))
            end
          end
        end

        # 修改 *.podspec.json
        def modify_podspec_json(file)
          @spec_hash['version'] = @version
          @spec_hash['source'] = {
            'git'=> @spec_hash['source']['git'],
            'tag'=> "#{@tag}"
          }
          File.open(file, 'w') do |f|
            f.write(@spec_hash)
          end
        end

        # 校验 podspec
        def lint_podspec(tip = "\n校验`#{@podspecs.first}`：\n")
          print "#{tip}".yellow
          argvs = [
            @podspecs.first,
            '--quick',
            '--allow-warnings'
          ]
          lint = Pod::Command::Spec::Lint.new(CLAide::ARGV.new(argvs))
          lint.validate!
          lint.run
        end

        # 推送 tag 到远端
        def git_tag_push
          print "\n推送commit到远端git仓库`#{@remote}/#{current_branch}`：\n".yellow
          begin
            `git add #{@podspecs.first}`
            `git commit -m #{@commit_msg}`
            `git push #{@remote} #{current_branch}`
          rescue Pod::StandardError => e
            @error = e
            print "推送commit到远端git仓库`#{@remote}/#{current_branch}`失败:#{e}".red
          end

          print "\n创建tag:`#{@tag}`并推送至远端：\n".yellow
          begin
            `git tag -a #{@tag} -m #{@tag_msg}`
            `git push #{@remote} --tags`
          rescue Pod::StandardError => e
            @error = e
            print "创建tag:`#{@tag}`并推送至远端失败:#{e}".red
          end
        end

        # 询问用户是否推送 podspec 到 spec 仓库
        def ask_push_podspec_to_repo
          answer = asker.ask("\n是否推送podspec到spec仓库？", true, nil, {'1'=> 'YES', '2' => 'NO'})
          if answer == '1'
            @spec_repo = asker.ask("\n请输入本地spec仓库名称（可以通过`pod repo list`查看）：", true)
            repos = `pod repo list`.split("\n").reject { |repo| repo == '' || repo =~ /^-/ }
            unless repos.include?(@spec_repo)
              print "本地不存在`#{@spec_repo}`仓库，请先`pod repo add`添加该仓库\n"
              return
            end
            unless @spec_repo == ''
              push_podspec_to_repo
            end
          else
            print "跳过推送podspec到spec仓库\n"
          end
        end

        # 推送 podspec 到 spec repo
        def push_podspec_to_repo
          print "\n推送`#{@podspecs.first}`到`#{@spec_repo}`仓库".yellow
          argvs = [
            @spec_repo,
            @podspecs.first,
            '--allow-warnings'
          ]
          begin
            push = Pod::Command::Repo::Push.new(CLAide::ARGV.new(argvs))
            push.validate!
            push.run
          rescue Pod::StandardError => e
            @error = e
            print "推送`#{@podspecs.first}`到`#{@spec_repo}`仓库失败！#{e}".red
          end
        end

        def exit(status = -1, msg)
          print "#{msg}".red
          Process.exit(status)
        end

        def asker
          @asker ||= begin
                       Helper::Asker.new()
                     end
        end

        # 获取当前分支
        def current_branch
          @current_branch ||= begin
                                `git branch`.split(' ')[1]
                              end
        end

        # 检查当前目录是否有podspec
        def check_podspec_exist?
          @podspecs = Dir.glob("*.{#{PODSPEC_EXT.join(',')}}")
          if @podspecs.empty?
            return false
          end
          true
        end

      end
    end
  end
end
