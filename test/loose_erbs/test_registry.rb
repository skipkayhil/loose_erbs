# frozen_string_literal: true

require "test_helper"

class TestRegistry < Minitest::Test
  def test_scaffold_files_are_registered
    registry = LooseErbs::Registry.new(lookup_context)

    assert_predicate (absolute_scaffolds_paths - registry.instance_variable_get(:@map).keys), :empty?
  end

  def test_lookup_unknown_dependency
    registry = LooseErbs::Registry.new(lookup_context)

    assert_nil registry.lookup("does/not/exist")
  end


  private
    def lookup_context
      ActionView::LookupContext.new([scaffolds_path])
    end

    def scaffolds_path
      File.expand_path("../dummy/app/views", __dir__)
    end

    def absolute_scaffolds_paths
      [
        "layouts/application.html.erb",
        "posts/_form.html.erb",
        "posts/_post.html.erb",
        "posts/edit.html.erb",
        "posts/index.html.erb",
        "posts/new.html.erb",
        "posts/show.html.erb",
      ].map { scaffolds_path + "/" + _1 }
    end
end
