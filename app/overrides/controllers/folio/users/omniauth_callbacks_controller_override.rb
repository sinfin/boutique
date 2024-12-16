# frozen_string_literal: true

Folio::Users::OmniauthCallbacksController.class_eval do
  include Boutique::AfterSignInSessionUpdate

  private
    def after_sign_in
      after_sign_in_session_update
    end
end
