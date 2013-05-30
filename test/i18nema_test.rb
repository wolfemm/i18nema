require 'helper'
require 'yaml'

class I18nemaTest < Test::Unit::TestCase
  def setup
    @data = {
      foo: {
        bar: "lol"
      },
      baz: %w{
        asdf
        qwerty
      },
      stuff: [
        true,
        true,
        false,
        nil,
        1,
        1.1,
        :foo
      ]
    }
    @backend = I18nema::Backend.new
    @backend.store_translations :en, @data
  end

  def test_yaml_parity
    assert_equal({en: @data}, @backend.direct_lookup)
  end

  def test_scoping
    assert_equal({bar: "lol"},
                 @backend.direct_lookup("en", "foo"))
    assert_equal "lol",
                 @backend.direct_lookup("en", "foo", "bar")
    assert_equal nil,
                 @backend.direct_lookup("poo")
  end

  def test_merging
    @backend.store_translations :en, foo: "replaced!", wat: "added!"
    assert_equal "replaced!",
                 @backend.direct_lookup("en", "foo")
    assert_equal ["asdf", "qwerty"],
                 @backend.direct_lookup("en", "baz")
    assert_equal "added!",
                 @backend.direct_lookup("en", "wat")
  end

  def test_reload
    @backend.reload!
    assert_equal({}, @backend.direct_lookup)
  end

  def test_available_locales
    @backend.store_translations :es, foo: "hola"
    assert_equal ['en', 'es'],
                 @backend.available_locales.map(&:to_s).sort
  end

  def test_invalid_yml
    backend = I18nema::Backend.new

    exception = assert_raise(I18nema::Backend::LoadError) {
      backend.load_yml_string("string")
    }
    assert_equal("root yml node is not a hash", exception.message)
    assert_equal({}, backend.direct_lookup)

    # FIXME ... ruby syck does this differently, and we get a non
    # i_object_t as the root node, causing delete_object to asplode when
    # it tries to free a garbage pointer
    #
    #exception = assert_raise(I18nema::Backend::LoadError) {
    #  backend.load_yml_string("en:\n  foo: \"lol\"\n\tbar: notabs!")
    #}
    #assert_match(/TAB found in your indentation/, exception.message)
    #assert_equal({}, backend.direct_lookup)

    exception = assert_raise(I18nema::Backend::LoadError) {
      backend.load_yml_string("en:\n  &a [*a]")
    }
    assert_match(/bad anchor `a'/, exception.message)
    assert_equal({}, backend.direct_lookup)
  end
end
