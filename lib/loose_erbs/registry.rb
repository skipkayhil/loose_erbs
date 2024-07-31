# frozen_string_literal: true

module LooseErbs
  class Registry
    def initialize(lookup_context)
      @map = {}
      @view_paths = lookup_context.view_paths

      @view_paths.each do |view_path|
        Dir["#{view_path}/**/*.erb"].each { register(_1, view_path.path) }
      end
    end

    def dependencies_for(identifier)
      template = @map.fetch(identifier).fetch(:template)

      LooseErbs.parser_class.call(identifier, template, @view_paths).uniq.map do |pathish|
        lookup(pathish) || begin
          warn("Couldn't resolve dependency of '#{identifier}': #{pathish}")

          "UNKNOWN TEMPLATE: #{pathish}"
        end
      end
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

    def register(path, view_path)
      @map[path] = {
        template: ActionView::Template.new(
                    File.read(path),
                    path,
                    ActionView::Template::Handlers::ERB,
                    locals: nil,
                    format: :html,
                  ),
        view_path: view_path,
      }
    end

    def to_graph
      Graph.new(@map, self)
    end
  end
end
