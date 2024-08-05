# frozen_string_literal: true

module LooseErbs
  class NotLooseVisitor
    def initialize
      @not_loose_identifiers = Set.new
    end

    def visit(node)
      return unless loose?(node)

      @not_loose_identifiers << node.template.identifier if node.template

      node.children.each { visit(_1) }
    end

    def loose?(node)
      !@not_loose_identifiers.include?(node.template&.identifier)
    end

    def to_filter
      method(:loose?)
    end

    def to_proc
      method(:visit).to_proc
    end
  end
end
