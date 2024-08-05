# frozen_string_literal: true

require "test_helper"
require "stringio"

class TestLooseErbs < Minitest::Test
  def test_default_output
    io = StringIO.new

    in_dummy_app do
      LooseErbs::Cli.new(nil, out: io).run
    end

    assert_equal <<~OUT, io.string

    Loose ERBs:
    #{Dir.pwd}/test/dummy/app/views/posts/what.html.erb
    #{Dir.pwd}/test/dummy/app/views/unknown/unknown.html.erb
    OUT
  end

  def test_all_output
    io = StringIO.new

    in_dummy_app do
      cli = LooseErbs::Cli.new(nil, out: io)
      cli.instance_variable_get(:@options)[:all] = true
      cli.run
    end

    assert_equal <<~OUT, io.string

    All ERBs:
    #{Dir.pwd}/test/dummy/app/views/layouts/application.html.erb
    #{Dir.pwd}/test/dummy/app/views/posts/_form.html.erb
    #{Dir.pwd}/test/dummy/app/views/posts/_post.html.erb
    #{Dir.pwd}/test/dummy/app/views/posts/edit.html.erb
    #{Dir.pwd}/test/dummy/app/views/posts/index.html.erb
    #{Dir.pwd}/test/dummy/app/views/posts/new.html.erb
    #{Dir.pwd}/test/dummy/app/views/posts/show.html.erb
    #{Dir.pwd}/test/dummy/app/views/posts/what.html.erb
    #{Dir.pwd}/test/dummy/app/views/unknown/unknown.html.erb
    OUT
  end

  def test_trees_output
    io = StringIO.new

    in_dummy_app do
      cli = LooseErbs::Cli.new(nil, out: io)
      cli.instance_variable_get(:@options)[:trees] = true
      cli.run
    end

    assert_equal <<~OUT, io.string

    Loose Trees:
    #{Dir.pwd}/test/dummy/app/views/posts/what.html.erb

    #{Dir.pwd}/test/dummy/app/views/unknown/unknown.html.erb
    └── UNKNOWN TEMPLATE: does/not/exist

    OUT
  end

  def test_all_trees_output
    io = StringIO.new

    in_dummy_app do
      cli = LooseErbs::Cli.new(nil, out: io)
      cli.instance_variable_get(:@options)[:all] = true
      cli.instance_variable_get(:@options)[:trees] = true
      cli.run
    end

    assert_equal <<~OUT, io.string

    All Trees:
    #{Dir.pwd}/test/dummy/app/views/layouts/application.html.erb

    #{Dir.pwd}/test/dummy/app/views/posts/_form.html.erb

    #{Dir.pwd}/test/dummy/app/views/posts/_post.html.erb

    #{Dir.pwd}/test/dummy/app/views/posts/edit.html.erb
    └── #{Dir.pwd}/test/dummy/app/views/posts/_form.html.erb

    #{Dir.pwd}/test/dummy/app/views/posts/index.html.erb
    └── #{Dir.pwd}/test/dummy/app/views/posts/_post.html.erb

    #{Dir.pwd}/test/dummy/app/views/posts/new.html.erb
    └── #{Dir.pwd}/test/dummy/app/views/posts/_form.html.erb

    #{Dir.pwd}/test/dummy/app/views/posts/show.html.erb
    └── #{Dir.pwd}/test/dummy/app/views/posts/_post.html.erb

    #{Dir.pwd}/test/dummy/app/views/posts/what.html.erb

    #{Dir.pwd}/test/dummy/app/views/unknown/unknown.html.erb
    └── UNKNOWN TEMPLATE: does/not/exist

    OUT
  end

  private
    def in_dummy_app(&block)
      Dir.chdir("test/dummy", &block)
    end
end
