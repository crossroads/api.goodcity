module StateMachineScope

  extend ActiveSupport::Concern

  included do
    scope :in_states, ->(states) { where(state: states) }
  end

  module ClassMethods

    def valid_state?(state)
      valid_states.include?(state)
    end

    def valid_states
      state_machine.states.map {|state| state.name.to_s }
    end

    def valid_events
      state_machine.events.map {|event| event.name.to_s }
    end

    def default_state
      state_machine.states.detect{ |state| state.initial }.try(:name).try(:to_s)
    end

  end

end
