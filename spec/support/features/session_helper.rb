require 'omniauth_spec_helper'

module Features
  module SessionHelper
    VALID_PASSWORD = 'Val!dPassw0rd'.freeze

    def sign_up_with(email)
      visit new_user_registration_path
      fill_in 'Email', with: email
      click_button 'Sign up'
    end

    def signin(email, password)
      visit new_user_session_path
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      # select 'Applicant, Petitioner, or  Requester'
      click_button 'Log in'
    end

    def sign_up_with_and_set_password_for(email = nil, reset_session = false)
      email ||= Faker::Internet.email
      sign_up_with(email)
      user = User.find_by_email(email)
      Capybara.reset_session! if reset_session
      confirm_last_user
      fill_in 'user[password]', with: VALID_PASSWORD
      fill_in 'user[password_confirmation]', with: VALID_PASSWORD
      click_button 'Submit'
      user
    end

    def sign_up_and_2fa(email = nil, reset_session = false)
      user = sign_up_with_and_set_password_for(email, reset_session)
      check 'Email'
      uncheck 'Mobile'
      click_button 'Submit'
      fill_in 'code', with: user.otp_code
      click_button 'Submit'
      fill_in_security_answers
      click_button 'Submit'
      user
    end

    def sign_in_user(user = create(:user))
      signin(user.email, user.password)
      user
    end

    def sign_in_with_warden(user)
      login_as(user, scope: :user, run_callbacks: false)
      allow(user).to receive(:need_two_factor_authentication?).and_return(false)
      visit dashboard_index_path
    end

    def sign_in_and_2fa_user(user = create_user([SecondFactor.find_by_name('Email')]))
      sign_in_with_warden(user)

      user
    end

    def create_user(tfa)
      create(:user, :signed_up, second_factors: tfa)
    end

    def second_factor_type(type)
      return [email_2fa] if type == 'email'
      return [mobile_2fa] if type == 'mobile'
      return [email_2fa, mobile_2fa] if type == 'all'
    end

    def email_2fa
      SecondFactor.find_by_name('Email')
    end

    def mobile_2fa
      SecondFactor.find_by_name('Mobile')
    end

    def confirm_last_user
      @raw_confirmation_token, = Devise.token_generator.generate(User, :confirmation_token)

      User.last.update(
        confirmation_token: @raw_confirmation_token, confirmation_sent_at: Time.current)
      visit "/users/confirmation?confirmation_token=#{@raw_confirmation_token}"
    end

    def visit_manage_users
      @admin = sign_in_and_2fa_admin
      visit dashboard_index_path
      click_link 'Manage Users'
    end

    def search_for_user(email)
      sign_in_tech_support
      fill_in('email', with: email)
      click_button('user_search')
    end

    def reset_user(email)
      sign_in_tech_support
      fill_in('email', with: email)
      click_button('user_search')
      click_link('Reset Password/Account')
    end

    def sign_in_and_2fa_admin
      user = create(:user, :signed_up, :admin)
      sign_in_and_2fa_user(user)
    end

    def sign_in_tech_support
      user = create(:user, :signed_up, :tech_support)
      sign_in_and_2fa_user(user)
    end
  end
end