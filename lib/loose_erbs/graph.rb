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

    class NotLooseVisitor
      def initialize
        @not_loose_identifiers = Set.new
      end

      def visit(node)
        return unless loose?(node)

        @not_loose_identifiers << node.identifier

        node.children.each { visit(_1) }
      end

      def loose?(node)
        !@not_loose_identifiers.include?(node.identifier)
      end

      def to_filter
        method(:loose?)
      end
    end

    class Node
      attr_reader :children, :identifier, :template, :view_path

      def initialize(identifier, template, view_path)
        @identifier = identifier
        @template = template
        @children = []
        @view_path = view_path
      end

      def accept(visitor)
        visitor.visit(self)
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
      @node_map = template_map.to_h { |path, val| [path, Node.new(path, val[:template], val[:view_path])] }
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
      end

      def assign_children!(node)
        registry.dependencies_for(node.identifier).each do |identifier|
          # warn("No template registered for path: #{template.identifier}")
          node.children << @node_map.fetch(identifier) { Node.new(identifier, nil, "") }
        end
      end
  end
end
