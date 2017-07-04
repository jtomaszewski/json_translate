module JSONTranslate
  module Translates
    SUFFIX = "_translations".freeze

    def translates(*attrs)
      include InstanceMethods

      class_attribute :translated_attribute_names

      self.translated_attribute_names = attrs

      attrs.each do |attr_name|
        define_method attr_name do
          read_json_translation(attr_name)
        end

        define_method "#{attr_name}=" do |value|
          write_json_translation(attr_name, value)
        end

        define_singleton_method "with_#{attr_name}_translation" do |value, locale = I18n.locale|
          quoted_translation_store = connection.quote_column_name("#{attr_name}#{SUFFIX}")
          translation_hash = { "#{locale}" => value }
          where("#{quoted_translation_store} @> :translation::jsonb", translation: translation_hash.to_json)
        end
      end

      send(:prepend, ActiveRecordWithJSONTranslate)
    end

    def translates?
      included_modules.include?(InstanceMethods)
    end
  end
end
