# frozen_string_literal: true

module LooseErbs
  class Registry
    def initialize(lookup_context)
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

    # this feels like a hack around not using view paths...
    def lookup(pathish)
      wrapper = Pathname.new(pathish)

      if wrapper.absolute?
        # /home/hartley/test/dm/app/views/posts/form
        partial_path = wrapper.join("../_#{wrapper.basename}.html.erb").to_s

        return partial_path if @map.key? partial_path

        # The DependencyTracker always puts the partial under the parent's
        # namespace even if it could be found under a controller's super's
        # namespace.
        @view_paths.each do |view_path|
          partial_path = Pathname.new(view_path).join("application/_#{wrapper.basename}.html.erb").to_s

          return partial_path if @map.key? partial_path
        end
      else
        @view_paths.each do |view_path|
          # DependencyTracker removes the _ from partial pathishs
          # posts/post
          partial_path = Pathname.new(view_path).join(pathish).join("../_#{wrapper.basename}.html.erb").to_s

          return partial_path if @map.key? partial_path

          # Using the raw RenderParser returns a pathish with the partial _
          # components/_badge
          partial_path = Pathname.new(view_path).join(pathish).join("../#{wrapper.basename}.html.erb").to_s

          return partial_path if @map.key? partial_path
        end
      end

      nil
    end

    private
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
