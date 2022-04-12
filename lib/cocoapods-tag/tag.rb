require 'cocoapods-tag/helper/asker'

module Pod
  class Tag
    include Pod

    GITHUB_DOMAIN = "github.com".freeze
    GIT_REPO = ".git".freeze
    PODSPEC_EXT = %w[podspec podspec.json].freeze

    def initialize(version, tag, commit_msg, tag_msg, spec_repo = nil, quick = false, remote_name = nil)
      @version = version || raise(Informative, "缺少必填参数`version`")
      @tag = tag || raise(Informative, "缺少必填参数`tag`")
      @commit_msg = commit_msg || raise(Informative, "缺少必填参数`commit_msg`")
      @tag_msg = tag_msg || "v#{@tag}"
      @spec_repo = spec_repo
      @quick = quick
      @remote = remote_name
    end

    public

    def create
      require 'cocoapods-tag/native/validator'

      # 欢迎语
      welcome_message
      # 正则校验版本号
      check_version
      # 检查本地是否有 spec_repo
      check_spec_repo if @spec_repo
      # 检查 git repo
      check_git_repo
      # 加载 podspec
      load_podspec
      # 修改前校验 podspec
      lint_podspec("\n修改前校验`#{podspec}`\n")
      # 修改 podspec
      modify_podspec
      # 修改后校验 podspec
      lint_podspec("\n修改后校验`#{podspec}`\n")
      # 推送 commit 到远端
      git_commit_push
      # 推送 tag 到远端
      git_tag_push
      # 推送 podspec 到 spec repo
      push_podspec_to_repo if @spec_repo
      # 结束语
      done_message
    end

    private

    def welcome_message
      message = <<-MSG
👏🏻欢迎使用 `cocoapods-tag` 插件👏🏻
👏🏻version: #{CocoapodsTag::VERSION}👏🏻

      MSG
      print message.green
    end

    def done_message
      print "\n🌺 恭喜你完成任务 🌺\n".green
    end

    # 正则校验版本号
    def check_version
      unless Pod::Vendor::Gem::Version.correct?(@version)
        msg = <<-ERROR
版本号`#{@version}`格式不正确
版本号必须以数字`0-9`开头，可以包含数字`0-9`、字母`a-z A-Z`，特殊字符只能是`.`和`-`
具体请参考CocoaPods校验版本号的正则：
#{Pod::Vendor::Gem::Version::ANCHORED_VERSION_PATTERN}
        ERROR
        raise Informative, msg
      end
    end

    # 检查本地 spec_repo
    def check_spec_repo
      print "检查本地spec仓库\n".yellow
      repos = `pod repo list`.split("\n").reject { |repo| repo == '' || repo =~ /^-/ }
      unless repos.include?(@spec_repo)
        raise Informative, "本地不存在`#{@spec_repo}`仓库，请先使用`pod repo add`添加该仓库或使用`pod repo list`查看其他仓库"
      end
    end

    # 检查 git repo
    def check_git_repo
      print "检查本地git仓库\n".yellow

      # 本地是否有 .git 目录
      git_repo = File.join(Dir.pwd, GIT_REPO)
      raise Informative, "`#{Dir.pwd}`不存在git仓库，请先使用`git init`初始化git仓库" unless File.exist?(git_repo)

      # 是否与远端仓库关联
      raise Informative, "本地git仓库没有与远端仓库关联，请先使用`git remote add`关联远端仓库" if remote.nil?

      unless @quick
        # 校验本地 git 是否与远端仓库同步
        print "\n检查本地git仓库是否与远端仓库同步\n".yellow
        local_commit = `git rev-parse #{remote}/HEAD`.chomp
        remote_commit = `git ls-remote --head #{remote} #{current_branch}`.split("\t")[0]
        unless local_commit == remote_commit
          msg = <<-MSG
本地git仓库没有与远端仓库同步，请先执行以下操作：
1.`git pull`或`git fetch + git rebase`拉取最新代码
2.`git push`推送本地仓库commit
          MSG
          raise Informative, msg
        end

        # 检查本地是否已经有该 tag
        print "\n检查本地仓库是否有tag:`#{@tag}`\n".yellow
        raise Informative, "本地已经存在tag:#{@tag}" if `git tag`.split("\n").include?(@tag)

        # 判断远端是否已经有该 tag
        print "\n检查远端仓库是否有tag:`#{@tag}`\n".yellow
        tags = `git ls-remote --tags #{remote}`.split("\n").select { |tag| tag.include?("refs/tags/#{@tag}") }
        raise Informative, "远端仓库已经有该tag:#{@tag}" unless tags.empty?
      end

    end

    # 加载 podspec
    def load_podspec
      raise Informative, "`#{Dir.pwd}`不存在podspec" if podspec.nil?

      @spec = Specification.from_file(podspec)
      raise Informative, "加载`#{podspec}`失败！" if @spec.nil?

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
    end

    # 修改podspec
    def modify_podspec
      return if podspec.nil?

      print "\n修改`#{podspec}`\n".yellow
      file = File.join(Dir.pwd, "#{podspec}")
      # 匹配文件名后缀
      if podspec =~ /.podspec$/
        modify_podspec_ruby(file)
      elsif podspec =~ /.podspec.json$/
        modify_podspec_json(file)
      end
      print "`#{podspec}` modified done\n"
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

    # 推送 commit
    def git_commit_push
      print "\n推送commit到远端git仓库`#{remote}/#{current_branch}`\n".yellow
      begin
        `git add #{podspec}`
        `git commit -m "#{@commit_msg}"`
        `git push #{remote} #{current_branch}`
      rescue Pod::StandardError => e
        @error = e
        print "推送commit到远端git仓库`#{remote}/#{current_branch}`失败:#{e}".red
      end
    end

    # 推送 tag 到远端
    def git_tag_push
      print "\n创建tag:`#{@tag}`并推送至远端`#{remote}`\n".yellow
      begin
        `git tag -a #{@tag} -m "#{@tag_msg}"`
        `git push #{remote} #{@tag}`
      rescue Pod::StandardError => e
        @error = e
        print "创建tag:`#{@tag}`并推送至远端失败:#{e}".red
      end
    end

    # 推送 podspec 到 spec repo
    def push_podspec_to_repo
      print "\n推送`#{podspec}`到`#{@spec_repo}`仓库\n".yellow
      argvs = [
        @spec_repo,
        podspec,
        '--allow-warnings'
      ]
      begin
        push = Pod::Command::Repo::Push.new(CLAide::ARGV.new(argvs))
        push.validate!
        push.run
      rescue Pod::StandardError => e
        @error = e
        print "推送`#{podspec}`到`#{@spec_repo}`仓库失败！#{e}".red
      end
    end

    # 校验 podspec
    def lint_podspec(tip = "\n校验`#{podspec}`\n")
      print "#{tip}".yellow
      argvs = [
        podspec,
        '--quick',
        '--allow-warnings'
      ]
      lint = Pod::Command::Spec::Lint.new(CLAide::ARGV.new(argvs))
      lint.validate!
      lint.run
    end

    # 获取当前分支
    def current_branch
      @current_branch ||= begin
                            `git branch`.split(' ')[1]
                          end
    end

    # 获取当前目录下的 podspec
    def podspec
      @podspec ||= begin
                     podspec = nil
                     podspecs = Dir.glob("*.{#{PODSPEC_EXT.join(',')}}")
                     unless podspecs.empty?
                       podspec = podspecs.first
                     end
                     podspec
                   end
    end

    def asker
      @asker ||= begin
                   Helper::Asker.new()
                 end
    end

    # 获取远端仓库名
    def remote
      @remote ||= begin
                    remote = nil
                    remotes = `git remote`.split("\n")
                    remote = remotes.first unless remotes.empty?
                    if remotes.size > 1
                      count = 0
                      selections = {}
                      remotes.map do |r|
                        count += 1
                        selections["#{count}"] = r
                      end
                      key = asker.ask("\n本地有多个关联的远端仓库，请选择：", true, nil, selections)
                      remote = remotes["#{key}".to_i - 1]
                    end
                    remote
                  end
    end

  end
end
