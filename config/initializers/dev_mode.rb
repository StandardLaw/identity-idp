require 'feature_management'
if FeatureManagement.enable_dev_mode?
  # load libraries or overrides to be enabled with dev_mode:
  require File.join(Rails.root, 'lib', 'i18n_override.rb')
end
