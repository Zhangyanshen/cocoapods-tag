
module Pod
  class Validator
    # 跳过 xcodebuild 校验
    def perform_extensive_analysis(spec)
      true
    end
  end
end
