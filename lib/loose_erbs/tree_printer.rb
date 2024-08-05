# frozen_string_literal: true

module LooseErbs
  class TreePrinter
    attr_reader :out

    def initialize(out)
      @out = out
    end

    def to_proc
      method(:print_tree).to_proc
    end

    def print_tree(root)
      node_stack = [[root, -1]]
      seen_nodes = Set.new

      while !node_stack.empty?
        node, depth = node_stack.pop

        id =
          case node
          when ActionView::Digestor::Missing
            "UNKNOWN TEMPLATE: #{node.name}"
          else
            node.template.identifier
          end

        out.puts "#{("    " * depth) + "└── " if depth >= 0}#{id}"

        if seen_nodes.include?(node) && !node.children.empty?
          out.puts ("    " * (depth + 1)) + "└── ..."
        else
          seen_nodes << node

          node.children.each do |child|
            node_stack << [child, depth + 1]
          end
        end
      end
      out.puts
    end
  end
end
