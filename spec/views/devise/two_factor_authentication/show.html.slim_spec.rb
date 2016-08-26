require 'rails_helper'

describe 'devise/two_factor_authentication/show.html.slim' do
  context 'user has a phone' do
    let(:user) { build_stubbed(:user, :signed_up) }

    it 'has a localized heading' do
      render

      expect(rendered).to have_content t('headings.choose_otp_delivery')
    end

    it 'allows the user to select OTP delivery method' do
      allow(view).to receive(:current_user).and_return(user)
      render

      expect(rendered).to have_button(t('devise.two_factor_authentication.' \
                                        'buttons.confirm_with_sms'))
      expect(rendered).to have_button(t('devise.two_factor_authentication.' \
                                        'buttons.confirm_with_voice'))
    end

    it 'informs the user that an OTP will be sent to their number' do
      allow(view).to receive(:current_user).and_return(user)
      @phone_number = '***-***-1234'

      render

      expect(rendered).to have_content 'Please select how you would like to ' \
      'receive your one-time passcode for ***-***-1234'
    end
  end
end
