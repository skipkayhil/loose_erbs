# frozen_string_literal: true

module LooseErbs
  class Scanner
    singleton_class.attr_accessor :parser_class

    self.parser_class = if defined?(ActionView::RenderParser::Default)
      ActionView::RenderParser::Default
    else
      ActionView::RenderParser
    end

    def initialize(app = Rails.application)
      @app = app
    end

    def renders
      parsed_renders = []

      each_file_in(helper_paths) do |helper_path|
        parsed_renders.concat parsed_renders_in(helper_path)
      end.uniq

      parsed_renders
    end

    private
      attr_reader :app

      def helper_paths
        app.paths["app/helpers"]
      end

      def each_file_in(paths, &block)
        paths.each do |root_path|
          Dir["#{Rails.root.join(root_path)}/**/*.rb"].each(&block)
        end
      end

      def parsed_renders_in(file_path)
        parser = self.class.parser_class.new(file_path, File.read(file_path))
        parser.render_calls
      end
  end
end
