
module Pod
  class Command
    class Tag < Command
      class RepoList < Tag
        include Pod

        self.summary = '打印本地的 podspec 仓库'

        self.description = <<-DESC
        #{self.summary}
        DESC

        def self.options
          [
            ['--format=FORMAT', '输出结果格式化，可选项为`json/yml(yaml)/plain`'],
          ].concat(super)
        end

        def initialize(argv)
          @format = argv.option('format', 'plain')
          super
        end

        def run
          @sources = config.sources_manager.all
          if @format == 'json'
            print_json
          elsif @format == 'yml' || @format == 'yaml'
            print_yml
          else
            print_plain
          end
        end

        private

        def print_json
          require 'json'
          UI.puts JSON.pretty_generate(sources)
        end

        def print_yml
          require 'yaml'
          UI.puts sources.to_yaml
        end

        def print_plain
          list = Pod::Command::Repo::List.new(CLAide::ARGV.new([]))
          list.validate!
          list.run
        end

        def sources
          result = []
          @sources.each do |source|
            type = source.type
            if source.is_a?(Pod::CDNSource)
              type = 'CDN'
            elsif source.git?
              type = 'git'
            end
            source_hash = {
              'name' => source.name,
              'url' => source.url,
              'path' => source.repo.to_s,
              'type' => type
            }
            result << source_hash
          end
          result
        end

      end
    end
  end
end
