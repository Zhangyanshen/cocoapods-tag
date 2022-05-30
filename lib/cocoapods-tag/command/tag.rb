require 'cocoapods-tag/command/tag/auto'
# require 'cocoapods-tag/command/tag/create'
require 'cocoapods-tag/command/tag/spec_push'
require 'cocoapods-tag/command/tag/repo_list'

module Pod
  class Command
    class Tag < Command

      self.abstract_command = true
      self.default_subcommand = 'auto'

      self.summary = '🚀 方便地帮助 pod 库打 tag'
      self.description = <<-DESC
        #{self.summary}
      DESC

      def initialize(argv)
        super
      end

    end
  end
end
