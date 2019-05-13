# frozen_string_literal: true

module Jobs
  class DiscourseChatAddTypeField < Jobs::Onceoff
    def execute_onceoff(args)
      DiscourseChat::Rule.find_each do |rule|
        rule.save(validate: false)
      end
    end
  end
end
