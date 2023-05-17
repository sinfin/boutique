# frozen_string_literal: true

module StoresStateHistory
  extend ActiveSupport::Concern
  VIRTUAL_VOID_STATE = :void

  included do
    unless column_names.include?("aasm_state") && column_names.include?("state_history")
      raise "StoreStateHistory concern requires columns `aasm_state`(string) and `state_history`(json)"
    end

    before_validation :set_state_history

    attr_accessor :admin_user_for_state_history
  end

  def state_history
    super || []
  end

  def set_state_history
    sm_state_changes = changes["aasm_state"]
    if sm_state_changes.present?
      entry = {
        from: (sm_state_changes.first || VIRTUAL_VOID_STATE).to_s, #  :void on instance creation
        to: sm_state_changes.last.to_s,
        time: Time.current
      }

      if admin_user_for_state_history.present?
        entry[:admin_id] = admin_user_for_state_history.id
        entry[:admin_label] = admin_user_for_state_history.to_label
      end

      entry.stringify_keys! # keys in state_history are strings

      self.state_history = state_history + [entry] unless same_transition?(state_history.last, entry)
    end
  end

  def same_transition?(last_t, new_t)
    return false if last_t.blank?

    last_t.except("time") == new_t.except("time")
  end
end
