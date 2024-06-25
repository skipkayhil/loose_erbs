# frozen_string_literal: true

require "test_helper"

class TestRegistry < Minitest::Test
  def test_scaffold_files_are_registered
    registry = LooseErbs::Registry.new([scaffolds_path])

    assert_predicate (absolute_scaffolds_paths - registry.instance_variable_get(:@map).keys), :empty?
  end

  def test_lookup_unknown_dependency
    registry = LooseErbs::Registry.new([scaffolds_path])

    assert_equal "UNKNOWN TEMPLATE: unknown/unknown", registry.lookup("unknown/unknown")
  end

  def test_lookup_scaffold_dependencies
    registry = LooseErbs::Registry.new([scaffolds_path])

    absolute_scaffolds_paths.each do |abs_path|
      registry.dependencies_for(abs_path).each do |dependency_identifier|
        refute dependency_identifier.start_with?("UNKNOWN")
      end
    end
  end

  private
    ViewPaths = Struct.new(:path) do
      def to_s
        path
      end

      def to_str
        path
      end
    end

    def scaffolds_path
      ViewPaths.new(File.expand_path("../dummy/app/views", __dir__))
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
      ].map { scaffolds_path.path + "/" + _1 }
    end
end
