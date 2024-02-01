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
      registry = Registry.new(Pathname.pwd.join("app/views"))

      views.each { registry.register(_1) }

      registry.print
    end

    private

    def views
      Dir["#{Dir.pwd}/app/views/**/*.html.erb"]
    end
  end

  class Registry
    def initialize(root)
      @root = root
      @map = {}
    end

    def dependencies_for(template)
      LooseErbs.parser_class.call(template.identifier, template).map { lookup(_1) }
    end

    # this feels like a hack around not using view paths...
    def lookup(pathish)
      wrapper = Pathname.new(pathish)

      if wrapper.absolute?
        # /home/hartley/test/dm/app/views/posts/form
        partial_path = wrapper.join("../_#{wrapper.basename}.html.erb").to_s
        partial = @map[partial_path]

        return partial if partial

        partial_path = @root.join("application/_#{wrapper.basename}.html.erb").to_s
        partial = @map[partial_path]

        return partial if partial
      else
        # posts/post
        partial_path = @root.join(pathish)
        partial_path = partial_path.join("../_#{partial_path.basename}.html.erb").to_s
        partial = @map[partial_path]

        return partial if partial
      end

      raise pathish
    end

    def print
      puts to_graph.print
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

    private

    def to_graph
      Graph.new(@map, self)
    end
  end

  class Graph
    class Node
      attr_reader :children, :parents, :template

      def initialize(template)
        @template = template
        @children = []
        @parents = []
      end

      def print
        o = +""

        o << template.identifier << "\n"

        children.each do |child|
          child_out = child.print
          child_out.gsub!("\n", "\n    ")
          o << "└── " << child_out
        end

        o
      end
    end

    def initialize(map, registry)
      @node_map = map.transform_values { Node.new(_1) }
      @registry = registry

      nodes.each { process(_1) }
    end

    def print
      o = +""

      root_nodes.each { o << _1.print << "\n" }

      o
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
