module JSONTranslate
  module Translates
    module InstanceMethods
      def available_locales
        @available_locales ||= translated_attribute_names.map do |attr_name|
          hash = public_send("#{attr_name}#{SUFFIX}")
          hash ? hash.keys : []
        end.flatten.uniq
      end

      def translations
        @translations ||= available_locales.map do |locale|
          data = translated_attribute_names.map do |attr_name|
            [attr_name, read_json_translation(attr_name, locale, false)]
          end.to_h
          build_translation({ locale: locale }.merge(data))
        end
      end

      def build_translation(data = {})
        OpenStruct.new(data)
      end

      def translations_attributes=(translations_attributes)
        translations_attributes.each do |translation_attributes|
          locale = translation_attributes[:locale] || translation_attributes["locale"]
          next unless locale.present?

          destroy = translation_attributes[:_destroy] || translation_attributes["_destroy"]
          if [1, true, "true", "on"].include?(destroy)
            translated_attribute_names.map do |attr_name|
              write_json_translation(attr_name, nil, locale)
            end
          else
            translation_attributes.each do |attr_name, value|
              next if [:locale, "locale", :_destroy, "_destroy"].include?(attr_name)
              write_json_translation(attr_name, value, locale)
            end
          end
        end
      end

      def json_translate_fallback_locales(locale, attr_name)
        return locale if !I18n.respond_to?(:fallbacks)
        I18n.fallbacks[locale]
      end

      def read_json_translation(attr_name, locale = I18n.locale, with_fallbacks = true)
        translations = public_send("#{attr_name}#{SUFFIX}") || {}

        if with_fallbacks
          fallbacks = Array(json_translate_fallback_locales(locale, attr_name))
          available_locale = fallbacks.detect do |available_locale|
            !translations[available_locale.to_s].nil?
          end
          translations[available_locale.to_s]
        else
          translations[locale.to_s]
        end
      end

      def write_json_translation(attr_name, value, locale = I18n.locale)
        locale = locale.to_s
        if !translation_locales.include?(locale)
          raise InvalidTranslationLocale.new("Unknown locale #{locale}. Maybe you should replace `.translation_locales` method")
        end

        translation_store = "#{attr_name}#{SUFFIX}"
        translations = public_send(translation_store) || {}

        public_send("#{translation_store}_will_change!") unless translations[locale] == value
        if value.nil?
          translations.delete(locale)
        else
          translations[locale] = value
        end
        public_send("#{translation_store}=", translations)

        @available_locale = nil
        @translations = nil

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
