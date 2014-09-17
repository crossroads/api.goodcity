module StateMachineScope

  extend ActiveSupport::Concern

  included do
    scope :by_state, ->(state) { where(state: valid_state?(state) ? state : default_state) }
  end

  module ClassMethods

    def valid_state?(state)
      valid_states.include?(state)
    end

    def valid_states
      state_machine.states.map {|state| state.name.to_s }
    end

    def default_state
      state_machine.states.detect{ |state| state.initial }.try(:name).try(:to_s)
    end

  end

end
