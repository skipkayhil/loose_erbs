# frozen_string_literal: true

module LooseErbs
  class Registry
    def initialize(lookup_context)
      @lookup_context = lookup_context
      @map = {}
      @view_paths = lookup_context.view_paths

      lookup_context.view_paths.each do |view_path|
        all_erb_template_paths(view_path).each do |tp|
          ActionView::Digestor.tree(tp.virtual_path, lookup_context, tp.partial?, @map)
        end
      end
    end

    include Enumerable

    def each(&block)
      # ignore Missing nodes when iterating
      @map.values.each { yield _1 if _1.template }
    end

    def lookup(pathish)
      path = ActionView::TemplatePath.parse(pathish)

      template = @lookup_context.disable_cache do
        @lookup_context.find_all(path.name, [path.prefix], path.partial?, UNKNOWN_LOCALS).first
      end

      @map[template&.identifier]
    end

    private
      UNKNOWN_LOCALS = [].freeze

      def all_erb_template_paths(view_path)
        erb_template_paths = []

        dir_stack = [Pathname.new(view_path.path)]

        while dir = dir_stack.pop
          dir.each_child do |child_path|
            if child_path.file?
              next unless child_path.extname.end_with?(".erb")

              erb_template_paths << child_path.relative_path_from(view_path.path).to_s.remove(/\.[^\/]*\z/)
            else
              dir_stack << child_path
            end
          end
        end

        erb_template_paths.uniq!
        erb_template_paths.sort!
        erb_template_paths.map! { ActionView::TemplatePath.parse(_1) }
        erb_template_paths
      end
  end
end
