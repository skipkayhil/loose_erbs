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

  NoParentFilter = ->(node) { node.parents.empty? }
  PartialFilter = ->(node) { Pathname.new(node.identifier).basename.to_s.start_with?("_") }

  RegexpIncludeFactory = ->(regexp) {
    ->(node) { node.identifier.match?(regexp) }
  }
  RegexpExcludeFactory = ->(regexp) {
    ->(node) { !node.identifier.match?(regexp) }
  }

  class Cli
    def initialize(argv)
      @options = {}

      option_parser.parse!(into: @options)
    end

    def run
      require File.expand_path("./config/environment")

      Registry.new(ActionController::Base.view_paths).to_graph.print(filters)
    end

    private
      attr_reader :options

      def filters
        [
          NoParentFilter,
          (RegexpIncludeFactory.call(options[:include]) if options[:include]),
          (RegexpExcludeFactory.call(options[:exclude]) if options[:exclude]),
          (PartialFilter unless options[:all]),
        ].compact
      end

      def option_parser
        OptionParser.new do |parser|
          parser.on("--all", "Print all files with no parents (defaults to only partials)")
          parser.on("--include [REGEXP]", Regexp, "Only print files that match [REGEXP]")
          parser.on("--exclude [REGEXP]", Regexp, "Do not print files that match [REGEXP]")
        end
      end
  end

  class Graph
    class Printer
      def initialize(root)
        @node_stack = [[root, -1]]
        @seen_nodes = Set.new
      end

      def print
        while !@node_stack.empty?
          node, depth = @node_stack.pop

          puts "#{("    " * depth) + "└── " if depth >= 0}#{node.identifier}"

          if @seen_nodes.include?(node) && !node.children.empty?
            puts ("    " * (depth + 1)) + "└── ..."
          else
            @seen_nodes << node

            node.children.each do |child|
              @node_stack << [child, depth + 1]
            end
          end
        end
        puts
      end
    end

    class Node
      attr_reader :children, :identifier, :parents

      def initialize(identifier)
        @identifier = identifier
        @children = []
        @parents = []
      end
    end

    def initialize(keys, registry)
      @node_map = keys.to_h { [_1, Node.new(_1)] }
      @registry = registry

      nodes.each { process(_1) }
    end

    def print(filters)
      nodes_to_print = nodes

      filters.each do |filter|
        nodes_to_print.filter!(&filter)
      end

      nodes_to_print.each { Printer.new(_1).print }
    end

    private
      attr_reader :registry

      def nodes
        @node_map.values
      end

      def process(node)
        assign_children!(node)
        assign_parents!(node)
      end

      def assign_children!(node)
        registry.dependencies_for(node.identifier).each do |identifier|
          # warn("No template registered for path: #{template.identifier}")
          node.children << @node_map.fetch(identifier) { Node.new(identifier) }
        end
      end

      def assign_parents!(node)
        node.children.each do |child_node|
          child_node.parents << node
        end
      end
  end
end

require_relative "loose_erbs/registry"
