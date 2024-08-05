# frozen_string_literal: true

module LooseErbs
  class Registry
    def initialize(lookup_context)
      @map = {}
      @view_paths = lookup_context.view_paths

      lookup_context.view_paths.each do |view_path|
        # TODO: all_template_paths is nodoc
        view_path.all_template_paths.each do
          ActionView::Digestor.tree(_1.virtual_path, lookup_context, _1.partial?, @map)
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
  end
end
