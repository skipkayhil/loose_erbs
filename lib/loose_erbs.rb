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

  class Cli
    def run
      require File.expand_path("./config/environment")

      Registry.new.to_graph.print
    end
  end

  class Registry
    def initialize
      @map = {}
      @view_paths = ActionController::Base.view_paths

      @view_paths.each do |view_path|
        Dir["#{view_path}/**/*.erb"].each { register _1 }
      end
    end

    def dependencies_for(template)
      LooseErbs.parser_class.call(template.identifier, template, @view_paths).filter_map { lookup(_1) }
    end

    # this feels like a hack around not using view paths...
    def lookup(pathish)
      wrapper = Pathname.new(pathish)

      if wrapper.absolute?
        # /home/hartley/test/dm/app/views/posts/form
        partial_path = wrapper.join("../_#{wrapper.basename}.html.erb").to_s
        partial = @map[partial_path]

        return partial if partial

        # The DependencyTracker always puts the partial under the parent's
        # namespace even if it could be found under a controller's super's
        # namespace.
        @view_paths.each do |view_path|
          partial_path = Pathname.new(view_path).join("application/_#{wrapper.basename}.html.erb").to_s
          partial = @map[partial_path]

          return partial if partial
        end
      else
        # posts/post
        @view_paths.each do |view_path|
          partial_path = Pathname.new(view_path).join(pathish).join("../_#{wrapper.basename}.html.erb").to_s
          partial = @map[partial_path]

          return partial if partial
        end
      end

      warn("Couldn't resolve pathish: #{pathish}")
    end

    def register(path)
      @map[path] = ActionView::Template.new(
        File.read(path),
        path,
        ActionView::Template::Handlers::ERB,
        locals: nil,
        format: :html,
      )
    end

    def to_graph
      Graph.new(@map, self)
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

          if @seen_nodes.include?(node)
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
      attr_reader :children, :parents, :template

      def initialize(template)
        @template = template
        @children = []
        @parents = []
      end

      def identifier
        template.identifier
      end
    end

    def initialize(map, registry)
      @node_map = map.transform_values { Node.new(_1) }
      @registry = registry

      nodes.each { process(_1) }
    end

    def print
      root_nodes.each { Printer.new(_1).print }
    end

    private
      attr_reader :registry

      def root_nodes
        nodes.filter { _1.parents.empty? }
      end

      def nodes
        @node_map.values
      end

      def process(node)
        assign_children!(node)
        assign_parents!(node)
      end

      def assign_children!(node)
        registry.dependencies_for(node.template).each do |template|
          node_for_path = @node_map[template.identifier]
          # TODO: figure out what is nil
          next unless node_for_path

          node.children << node_for_path
        end
      end

      def assign_parents!(node)
        node.children.each do |child_node|
          child_node.parents << node
        end
      end
  end
end
