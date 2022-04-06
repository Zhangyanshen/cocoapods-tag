require 'cocoapods-tag/gem_version.rb'

class Helper
  class Asker

    def ask(question, required = false, pre_answer = nil, selections = nil, regx = nil )
      question_msg = "#{question}\n"
      question_msg += "旧值:#{pre_answer}\n" if pre_answer
      keys = []
      if selections && selections.is_a?(Hash)
        keys = selections.keys
        selections.each do |k, v|
          question_msg += "#{k}:#{v}\n"
        end
      end
      print question_msg.yellow
      answer = ''
      loop do
        show_prompt
        answer = STDIN.gets.chomp.strip
        # 判断是否为空
        if required && answer == ''
          print "该项为必填项\n"
          next
        end
        # 判断是否符合正则
        if regx && regx.is_a?(Hash)
          tip = regx['tip']
          pattern = regx['pattern']
          unless answer =~ pattern
            print "#{tip}\n"
            next
          end
        end
        # 有固定选项 && 输入的值不在选项中
        if selections && !keys.include?(answer)
          print "请输入#{keys}中的一个值:\n"
          next
        end
        break
      end
      answer
    end

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

    private

    def show_prompt
      print '> '.green
    end

  end
end
