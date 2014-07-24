# ISSUE with rails 4.1, while saving record gives following error:
# NoMethodError (protected method `around_validation' called for
# #<StateMachine::Machine>
#
# https://github.com/pluginaweek/state_machine/issues/251#issuecomment-32133267
#

module StateMachine
  module Integrations
    module ActiveModel
      public :around_validation
    end

    module ActiveRecord
      public :around_save
    end
  end
end
