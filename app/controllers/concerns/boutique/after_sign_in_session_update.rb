# frozen_string_literal: true

module Boutique::AfterSignInSessionUpdate
  extend ActiveSupport::Concern

  private
    def after_sign_in_session_update
      # store previous session ID before reset, allows to keep current order after login
      session[:id_before_login] = session.id.public_id
      session.options[:id] = session.instance_variable_get(:@by).generate_sid
      session.options[:renew] = false
    end
end
