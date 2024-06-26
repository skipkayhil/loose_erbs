# frozen_string_literal: true

module LooseErbs
  class Graph
    class Printer
      def initialize(root)
        @node_stack = [[root, -1]]
        @seen_nodes = Set.new
      end

      def print_tree
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

    class LooseVisitor
      def visit(node)
        return unless node.loose?

        node.not_loose!

        node.children.each { visit(_1) }
      end
    end

    class Node
      attr_reader :children, :identifier, :parents, :view_path

      def initialize(identifier, view_path)
        @identifier = identifier
        @children = []
        @parents = []
        @loose = true
        @view_path = view_path
      end

      def accept(visitor)
        visitor.visit(self)
      end

      def loose?
        @loose
      end

      def not_loose!
        @loose = false
      end

      def partial?
        Pathname.new(identifier).basename.to_s.start_with?("_")
      end

      def print
        puts identifier
      end

      def print_tree
        Printer.new(self).print_tree
      end
    end

    include Enumerable

    def initialize(template_map, registry)
      @node_map = template_map.to_h { |path, val| [path, Node.new(path, val[:view_path])] }
      @registry = registry

      each { process(_1) }
    end

    def each(&block)
      nodes.each(&block)
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
          node.children << @node_map.fetch(identifier) { Node.new(identifier, "") }
        end
      end

      def assign_parents!(node)
        node.children.each do |child_node|
          child_node.parents << node
        end
      end
  end
end
