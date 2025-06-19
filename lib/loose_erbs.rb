# frozen_string_literal: true

require "action_view"
require "action_view/dependency_tracker"
require "optparse"

require_relative "loose_erbs/version"

module LooseErbs
  TemplateFilter = ->(node) {
    !Pathname.new(node.template.identifier).basename.to_s.start_with?("_")
  }

  RegexpIncludeFactory = ->(regexp) {
    ->(node) { node.template.identifier.match?(regexp) }
  }
  RegexpExcludeFactory = ->(regexp) {
    ->(node) { !node.template.identifier.match?(regexp) }
  }

  class FilterChain
    def initialize(filters)
      @filters = filters
    end

    def filter!(elements)
      @filters.reduce(elements) do |filtered_elements, filter|
        filtered_elements.filter!(&filter)
      end
    end
  end

  class Cli
    def initialize(argv, out: $stdout)
      @options = {}
      @out = out

      option_parser.parse!(into: @options)
    end

    def run
      require File.expand_path("./config/environment")

      mark_entrypoints_as_not_loose! unless options[:all]

      nodes = registry.to_a

      FilterChain.new(filters).filter!(nodes) unless filters.empty?

      if nodes.empty?
        true
      elsif options[:trees]
        out.write "#{erb_descriptor} Trees:"

        printer = TreePrinter.new(out)

        nodes.each { out.puts; printer.print_tree(_1) }

        true
      else
        out.puts "#{erb_descriptor} ERBs:"

        nodes.each { out.puts _1.template.identifier }

        !!options[:all]
      end
    end

    private
      attr_reader :options, :out

      def erb_descriptor
        options[:all] ? "All" : "Loose"
      end

      def mark_entrypoints_as_not_loose!
        renders_in_helpers.each(&visitor)
        renders_in_controllers.each(&visitor)
      end

      def registry
        @registry ||= Registry.new(ActionController::Base.new.lookup_context)
      end

      def routes
        @routes ||= Routes.new(Rails.application)
      end

      def renders_in_controllers
        # TODO: explicit controller renders
        registry.select { TemplateFilter.call(_1) && routes.public_action_for?(_1) }
      end

      def renders_in_helpers
        Scanner.new.renders.filter_map { registry.lookup(_1) }
      end

      def visitor
        @visitor ||= NotLooseVisitor.new
      end

      def filters
        @filters ||= [
          (visitor.to_filter if only_output_loose_erbs?),
          (RegexpIncludeFactory.call(options[:include]) if options[:include]),
          (RegexpExcludeFactory.call(options[:exclude]) if options[:exclude]),
        ].compact
      end

      def only_output_loose_erbs?
        !options[:all]
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

require_relative "loose_erbs/not_loose_visitor"
require_relative "loose_erbs/registry"
require_relative "loose_erbs/routes"
require_relative "loose_erbs/scanner"
require_relative "loose_erbs/tree_printer"
