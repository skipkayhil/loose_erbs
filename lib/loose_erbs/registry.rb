# frozen_string_literal: true

module LooseErbs
  class Registry
    class UnregisteredTemplate
      def initialize(pathish)
        @pathish = pathish
      end

      def identifier
        "UNKNOWN TEMPLATE: #{@pathish}"
      end
    end

    def initialize
      @map = {}
      @view_paths = ActionController::Base.view_paths

      @view_paths.each do |view_path|
        Dir["#{view_path}/**/*.erb"].each { register _1 }
      end
    end

    def dependencies_for(template)
      LooseErbs.parser_class.call(template.identifier, template, @view_paths).uniq.map { lookup(_1) }
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
      UnregisteredTemplate.new(pathish)
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
end
