require 'i18n'

I18n.module_eval do
  class << self
    def translate_with_markup(*args)
      i18n_text = normal_translate(*args)
      return i18n_text unless FeatureManagement.enable_dev_mode? && i18n_text.is_a?(String)

      key = args.first.to_s
      rtn = i18n_text + additional_markup(key)

      rtn.html_safe
    end

    private

    def additional_markup(key)
      uri = get_loc_uri(key)
      return '' unless uri

      "<a href=\"#{uri}\" target=\"_blank\" class=\"ml1\">🔗</a>"
    end

    def get_loc_uri(key)
      file = find_key(key)

      return nil unless file

      base_uri = 'https://github.com/18F/identity-idp/tree/master/config/locales/'
      base_uri + file.split('/').last + '#L' + find_line_number(file, key).to_s
    end

    def find_line_number(file, key)
      # the i18n module does not maintain references to the source of a
      # translation, therefore, we are parsing and searching each instance
      # of a localized file to find the source of the translation.
      # this could most-certainly be improved :)
      match_line_in_file(file, get_line_regex(key))
    end

    def match_line_in_file(file, match_arr)
      File.foreach(file).with_index do |line, i|
        break i + 1 if line =~ /#{match_arr.join('|')}/
      end
    end

    # rubocop:disable AbcSize
    def get_line_regex(key)
      key_arr = key.split('.')
      spaces = 2 * key_arr.length
      last_key = key_arr.last

      match_str = ' ' * spaces + last_key + ':'

      localized_str = normal_translate(key)
      # values are stored in different ways. sometimes wrapped with quotes,
      # sometimes multiline, etc.
      match_with_value = match_str + ' ' + localized_str
      match_with_quotes = match_str + ' "' + localized_str
      match_with_multiline = match_str + ' >' # assuming match_str is on next line

      [match_with_value, match_with_quotes, match_with_multiline]
    end
    # rubocop:enable AbcSize

    def find_key(key)
      i18n_files.each do |file|
        location = traverse_file_for_key(file, key)
        return location if location
      end
      nil
    end

    def i18n_files
      Dir[Rails.root.join('config', 'locales', '*.{yml}').to_s]
    end

    def traverse_file_for_key(file, key)
      yml = YAML.load(File.open(file))[I18n.config.locale.to_s]

      elements = key.split('.')

      return file if deep_key_match?(yml, elements)
    end

    def deep_key_match?(hsh, keys)
      keys.inject(hsh) { |a, e| a[e] if a.is_a?(Hash) }
    end

    alias_method :normal_translate, :translate
    alias_method :translate, :translate_with_markup
  end
end
