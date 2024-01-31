# frozen_string_literal: true

require "action_view"
require "action_view/dependency_tracker"

require_relative "loose_erbs/version"

module LooseErbs
  singleton_class.attr_accessor :parser_class

  self.parser_class = if defined?(ActionView::DependencyTracker::RubyTracker)
    ActionView::DependencyTracker::RubyTracker
  else
    ActionView::DependencyTracker::RipperTracker
  end

  class Template
    class << self
      def from(path)
        new(path, File.read(path))
      end
    end

    attr_reader :path, :source

    def initialize(path, source)
      @path = path
      @source = source
    end

    def dependencies
      LooseErbs.parser_class.call(path, self)
    end

    def handler
      ActionView::Template::Handlers::ERB
    end

    def type
      ["text/html"]
    end

    def inspect
      path
    end
  end

  class Registry
    def initialize
      @map = {}
    end

    def print
      @map.values.each do |template|
        puts template.inspect

        template.dependencies.each do |dependency|
          puts "└── #{dependency}"
        end
      end
    end

    def register(path)
      @map[path] = Template.from(path)
    end
  end

  class Cli
    def run
      registry = Registry.new

      views.each { registry.register(_1) }

      registry.print
    end

    private

    def views
      Dir["#{Dir.pwd}/app/views/**/*.html.erb"]
    end
  end
end
