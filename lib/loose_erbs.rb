# frozen_string_literal: true

require "action_view"
require "action_view/dependency_tracker"
require "optparse"

require_relative "loose_erbs/version"

module LooseErbs
  singleton_class.attr_accessor :parser_class

  self.parser_class = if defined?(ActionView::DependencyTracker::RubyTracker)
    ActionView::DependencyTracker::RubyTracker
  else
    ActionView::DependencyTracker::RipperTracker
  end

  LooseFilter = ->(node) { node.loose? }

  RegexpIncludeFactory = ->(regexp) {
    ->(node) { node.identifier.match?(regexp) }
  }
  RegexpExcludeFactory = ->(regexp) {
    ->(node) { !node.identifier.match?(regexp) }
  }

  class FilterChain
    def initialize(filters)
      @filters = filters
    end

    def filter(elements)
      @filters.reduce(elements) do |filtered_elements, filter|
        filtered_elements.filter(&filter)
      end
    end
  end

  class Cli
    def initialize(argv)
      @options = {}

      option_parser.parse!(into: @options)
    end

    def run
      require File.expand_path("./config/environment")

      nodes = registry.to_graph

      unless options[:all]
        ruby_rendered_erbs = scanner.renders.map { registry.lookup(_1) }.to_set

        visitor = Graph::NotLooseVisitor.new

        # Get only the "root" nodes, which are:
        # - rendered from ruby (in a helper, TODO: controller/etc.) OR
        # - not a partial && match a publically accessible controller action (implicit renders)
        # and then mark them and their tree of dependencies as NotLoose
        nodes.select { |node|
          ruby_rendered_erbs.include?(node.identifier) ||
            (!node.partial? && routes.public_action_for?(node))
        }.each { _1.accept(visitor) }
      end

      nodes = FilterChain.new(filters).filter(nodes) unless filters.empty?

      if options[:trees]
        nodes.each(&:print_tree)

        true
      else
        puts "\nLoose ERBs:" unless nodes.empty?
        nodes.each(&:print)

        nodes.empty?
      end
    end

    private
      attr_reader :options

      def registry
        Registry.new(ActionController::Base.view_paths)
      end

      def routes
        @routes ||= Routes.new(Rails.application)
      end

      def scanner
        Scanner.new
      end

      def filters
        [
          LooseFilter,
          (RegexpIncludeFactory.call(options[:include]) if options[:include]),
          (RegexpExcludeFactory.call(options[:exclude]) if options[:exclude]),
        ].compact
      end

      def option_parser
        OptionParser.new do |parser|
          parser.on("--trees", "Print files and their dependencies")
          parser.on("--all", "Print all files with no parents (defaults to only partials)")
          parser.on("--include [REGEXP]", Regexp, "Only print files that match [REGEXP]")
          parser.on("--exclude [REGEXP]", Regexp, "Do not print files that match [REGEXP]")
        end
      end
  end
end

require_relative "loose_erbs/graph"
require_relative "loose_erbs/registry"
require_relative "loose_erbs/routes"
require_relative "loose_erbs/scanner"
