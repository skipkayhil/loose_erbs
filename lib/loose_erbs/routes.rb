# frozen_string_literal: true

module LooseErbs
  class Routes
    def initialize(app)
      @app = app
    end

    def public_action_for?(template_node)
      # This logic feels like it should be inside an object...
      template_pathname = Pathname.new(template_node.identifier)
      relative_template_pathname = template_pathname.relative_path_from(template_node.view_path)

      relative_path_components = relative_template_pathname.each_filename.to_a

      # TODO: we should check if layouts are actually used
      return true if relative_path_components.first == "layouts"

      *folders, file = relative_path_components

      controller = (folders.map { _1.camelize }.join("::") + "Controller").safe_constantize

      return false unless controller

      controller.public_instance_methods.include? file.split(".").first.to_sym
    end
  end
end
