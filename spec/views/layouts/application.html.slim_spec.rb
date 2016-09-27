require 'rails_helper'

describe 'layouts/application.html.slim' do
  include Devise::Test::ControllerHelpers

  context 'when dev mode enabled' do
    before do
      allow(FeatureManagement).to receive(:enable_dev_mode?).and_return(true)
    end

    after do
      allow(FeatureManagement).to receive(:enable_dev_mode?).and_return(false)
    end

    it 'renders _dev_mode.html' do
      render

      expect(view).to render_template(partial: '_dev_mode')
    end
  end

  context 'when dev mode disabled' do
    before do
      allow(FeatureManagement).to receive(:enable_dev_mode?).and_return(false)
    end

    it 'does not render _dev_mode.html' do
      render

      expect(view).to_not render_template(partial: '_dev_mode')
    end
  end
end
