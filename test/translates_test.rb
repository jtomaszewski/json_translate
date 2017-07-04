# -*- encoding : utf-8 -*-
require 'test_helper'

class TranslatesTest < JSONTranslate::Test
  def test_assigns_in_current_locale
    I18n.with_locale(:en) do
      p = Post.new(:title => "English Title")
      assert_equal("English Title", p.title_translations['en'])
    end
  end

  def test_retrieves_in_current_locale
    p = Post.new(:title_translations => { "en" => "English Title", "fr" => "Titre français" })
    I18n.with_locale(:fr) do
      assert_equal("Titre français", p.title)
    end
  end

  def test_retrieves_in_current_locale_with_fallbacks
    I18n::Backend::Simple.include(I18n::Backend::Fallbacks)
    I18n.default_locale = :"en-US"

    p = Post.new(:title_translations => {"en" => "English Title"})
    I18n.with_locale(:fr) do
      assert_equal("English Title", p.title)
    end
  end

  def test_assigns_in_specified_locale
    I18n.with_locale(:en) do
      p = Post.new(:title_translations => { "en" => "English Title" })
      p.title_fr = "Titre français"
      assert_equal("Titre français", p.title_translations["fr"])
    end
  end

  def test_persists_changes_in_specified_locale
    I18n.with_locale(:en) do
      p = Post.create!(:title_translations => { "en" => "Original Text" })
      p.title_en = "Updated Text"
      p.save!
      assert_equal("Updated Text", Post.last.title_en)
    end
  end

  def test_retrieves_in_specified_locale
    I18n.with_locale(:en) do
      p = Post.new(:title_translations => { "en" => "English Title", "fr" => "Titre français" })
      assert_equal("Titre français", p.title_fr)
    end
  end

  def test_retrieves_in_specified_locale_with_fallbacks
    I18n::Backend::Simple.include(I18n::Backend::Fallbacks)
    I18n.default_locale = :"en-US"

    p = Post.new(:title_translations => { "en" => "English Title" })
    I18n.with_locale(:fr) do
      assert_equal("English Title", p.title_fr)
    end
  end

  def test_fallback_from_empty_string
    I18n::Backend::Simple.include(I18n::Backend::Fallbacks)
    I18n.default_locale = :"en-US"

    p = Post.new(:title_translations => { "en" => "English Title" })
    I18n.with_locale(:fr) do
      assert_equal("English Title", p.title_fr)
    end
  end

  def test_method_missing_delegates
    assert_raises(NoMethodError) { Post.new.nonexistant_method }
  end

  def test_method_missing_delegates_non_translated_attributes
    assert_raises(NoMethodError) { Post.new.other_fr }
  end

  def test_persists_translations_assigned_as_hash
    p = Post.create!(:title_translations => { "en" => "English Title", "fr" => "Titre français" })
    p.reload
    assert_equal({"en" => "English Title", "fr" => "Titre français"}, p.title_translations)
  end

  def test_persists_translations_assigned_to_localized_accessors
    p = Post.create!(:title_en => "English Title", :title_fr => "Titre français")
    p.reload
    assert_equal({"en" => "English Title", "fr" => "Titre français"}, p.title_translations)
  end

  def test_with_translation_relation
    p = Post.create!(:title_translations => { "en" => "Alice in Wonderland", "fr" => "Alice au pays des merveilles" })
    I18n.with_locale(:en) do
      assert_equal p.title_en, Post.with_title_translation("Alice in Wonderland").first.try(:title)
    end
  end

  def test_class_method_json_translates?
    assert_equal true, Post.json_translates?
    assert_equal true, PostDetailed.json_translates?
  end

  def test_translate_post_detailed
    p = PostDetailed.create!(
      :title_translations => {
        "en" => "Alice in Wonderland",
        "fr" => "Alice au pays des merveilles"
      },
      :comment_translations => {
        "en" => "Awesome book",
        "fr" => "Un livre unique"
      }
    )

    I18n.with_locale(:en) { assert_equal "Awesome book", p.comment }
    I18n.with_locale(:en) { assert_equal "Alice in Wonderland", p.title }
    I18n.with_locale(:fr) { assert_equal "Un livre unique", p.comment }
    I18n.with_locale(:fr) { assert_equal "Alice au pays des merveilles", p.title }
  end
end
