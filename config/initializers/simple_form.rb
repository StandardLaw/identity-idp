SimpleForm.setup do |config|
  config.button_class = 'btn btn-primary'
  config.boolean_label_class = nil
  config.error_notification_tag = :div

  config.wrappers :base do |b|
    b.use :html5
    b.use :input, class: 'field'
  end

  config.wrappers :vertical_form, tag: 'div', class: 'mb2', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label
    b.use :input, class: 'block col-12 field'
    b.use :error, wrap_with: { tag: 'div', class: 'error-description' }
  end

  config.default_wrapper = :vertical_form
end