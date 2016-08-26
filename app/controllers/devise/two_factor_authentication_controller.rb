require 'feature_management'

module Devise
  class TwoFactorAuthenticationController < DeviseController
    include ScopeAuthenticator
    include OtpDeliveryFallback

    prepend_before_action :authenticate_scope!
    before_action :verify_user_is_not_second_factor_locked
    before_action :handle_two_factor_authentication
    before_action :check_already_authenticated

    def new
      analytics.track_event('User requested a new OTP code')

      send_user_otp

      show_direct_otp_prompt
      flash[:notice] = t('devise.two_factor_authentication.user.new_otp_sent')
    end

    def show
      if use_totp?
        show_totp_prompt
      else
        @phone_number = user_decorator.masked_two_factor_phone_number
      end
    end

    def confirm
      @phone_number = user_decorator.masked_two_factor_phone_number
      @code_value = current_user.direct_otp if FeatureManagement.prefill_otp_codes?
    end

    def send_code
      analytics.track_event("User requested #{current_otp_delivery_method} OTP delivery")
      send_user_otp
      show_direct_otp_prompt
      flash[:success] = t("devise.two_factor_authentication.send_code." \
        "#{current_otp_delivery_method}")
    end

    def update
      reset_attempt_count_if_user_no_longer_locked_out

      if resource.authenticate_otp(params[:code].strip)
        handle_valid_otp
      else
        handle_invalid_otp
      end
    end

    private

    def check_already_authenticated
      redirect_to profile_path if user_fully_authenticated?
    end

    def use_totp?
      # Present the TOTP entry screen to users who are TOTP enabled,
      # unless the user explictly selects SMS or voice
      current_user.totp_enabled? && !use_sms_or_voice_otp_delivery?
    end

    def verify_user_is_not_second_factor_locked
      handle_second_factor_locked_resource if user_decorator.blocked_from_entering_2fa_code?
    end

    def reset_attempt_count_if_user_no_longer_locked_out
      return unless user_decorator.no_longer_blocked_from_entering_2fa_code?

      resource.update(second_factor_attempts_count: 0, second_factor_locked_at: nil)
    end

    def handle_valid_otp
      user_session[TwoFactorAuthentication::NEED_AUTHENTICATION] = false

      bypass_sign_in resource
      flash[:notice] = t('devise.two_factor_authentication.success')

      analytics.track_event('User 2FA successful')

      resource.update(second_factor_attempts_count: 0)

      redirect_valid_resource
    end

    def redirect_valid_resource
      redirect_to after_sign_in_path_for(resource)
    end

    def prompt_for_otp_reentry
      if current_otp_delivery_method == 'totp'
        show_totp_prompt
      else
        show_direct_otp_prompt
      end
    end

    def show_direct_otp_prompt
      redirect_to otp_confirm_path(delivery_method: current_otp_delivery_method)
    end

    def show_totp_prompt
      render :confirm_totp
    end

    def handle_invalid_otp
      analytics.track_event('User entered invalid 2FA code')

      update_invalid_resource if resource.two_factor_enabled?

      flash[:error] = t('devise.two_factor_authentication.attempt_failed')

      if user_decorator.blocked_from_entering_2fa_code?
        handle_second_factor_locked_resource
      else
        prompt_for_otp_reentry
      end
    end

    def update_invalid_resource
      resource.second_factor_attempts_count += 1
      # set time lock if max attempts reached
      resource.second_factor_locked_at = Time.zone.now if resource.max_login_attempts?
      resource.save
    end

    def handle_second_factor_locked_resource
      analytics.track_event('User reached max 2FA attempts')

      render :max_login_attempts_reached

      sign_out
    end

    def send_user_otp
      current_user.send_new_otp(delivery_method: current_otp_delivery_method)
    end

    def user_decorator
      @user_decorator ||= current_user.decorate
    end

    def fallback_confirmation_link
      if sms_enabled?
        otp_new_path(delivery_method: :voice)
      else
        otp_new_path(delivery_method: :sms)
      end
    end
  end
end
