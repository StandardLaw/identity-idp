module Devise
  class TwoFactorAuthenticationSetupController < DeviseController
    include PhoneConfirmation
    include ScopeAuthenticator

    prepend_before_action :authenticate_scope!
    before_action :authorize_otp_setup

    # GET /users/otp
    def index
      @two_factor_setup_form = TwoFactorSetupForm.new(resource)
    end

    # PATCH /users/otp
    def set
      @two_factor_setup_form = TwoFactorSetupForm.new(resource)

      if @two_factor_setup_form.submit(params[:two_factor_setup_form])
        process_valid_form
      else
        analytics.track_event('2FA setup: invalid phone number')
        render :index
      end
    end

    private

    def authorize_otp_setup
      if user_fully_authenticated?
        redirect_to(request.referrer || root_url)
      elsif resource.two_factor_enabled?
        redirect_to user_two_factor_authentication_path
      end
    end

    def process_valid_form
      update_metrics
      prompt_to_confirm_phone(
        @two_factor_setup_form.phone,
        @two_factor_setup_form.delivery_method
      )
    end

    def update_metrics
      analytics.track_event('2FA setup: valid phone number')
    end
  end
end
