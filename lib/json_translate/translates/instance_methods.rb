module JSONTranslate
  module Translates
    module InstanceMethods
      def json_translate_fallback_locales(locale, attr_name)
        return locale if !I18n.respond_to?(:fallbacks)
        I18n.fallbacks[locale]
      end

      def read_json_translation(attr_name, locale = I18n.locale)
        translations = public_send("#{attr_name}#{SUFFIX}") || {}

        available = Array(json_translate_fallback_locales(locale, attr_name)).detect do |available_locale|
          !translations[available_locale.to_s].nil?
        end

        translations[available.to_s]
      end

      def write_json_translation(attr_name, value, locale = I18n.locale)
        translation_store = "#{attr_name}#{SUFFIX}"
        translations = public_send(translation_store) || {}
        public_send("#{translation_store}_will_change!") unless translations[locale.to_s] == value
        if value.nil?
          translations.delete(locale.to_s)
        else
          translations[locale.to_s] = value
        end
        public_send("#{translation_store}=", translations)
        value
      end

      def respond_to_with_translates?(symbol, include_all = false)
        return true if parse_translated_attribute_accessor(symbol)
        respond_to_without_translates?(symbol, include_all)
      end

      def method_missing_with_translates(method_name, *args)
        translated_attr_name, locale, assigning = parse_translated_attribute_accessor(method_name)

        return method_missing_without_translates(method_name, *args) unless translated_attr_name

        if assigning
          write_json_translation(translated_attr_name, args.first, locale)
        else
          read_json_translation(translated_attr_name, locale)
        end
      end

      # Internal: Parse a translated convenience accessor name.
      #
      # method_name - The accessor name.
      #
      # Examples
      #
      #   parse_translated_attribute_accessor("title_en=")
      #   # => [:title, :en, true]
      #
      #   parse_translated_attribute_accessor("title_fr")
      #   # => [:title, :fr, false]
      #
      # Returns the attribute name Symbol, locale Symbol, and a Boolean
      # indicating whether or not the caller is attempting to assign a value.
      def parse_translated_attribute_accessor(method_name)
        return unless /\A(?<attribute>[a-z_]+)_(?<locale>[a-z]{2})(?<assignment>=?)\z/ =~ method_name

        translated_attr_name = attribute.to_sym
        return unless translated_attribute_names.include?(translated_attr_name)

        locale    = locale.to_sym
        assigning = assignment.present?

        [translated_attr_name, locale, assigning]
      end
    end
  end
end
