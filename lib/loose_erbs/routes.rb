# frozen_string_literal: true

module LooseErbs
  class Routes
    def initialize(app)
      @app = app
    end

    def public_action_for?(template_node)
      relative_path_components = template_node.logical_name.split("/")

      # TODO: we should check if layouts are actually used
      return true if relative_path_components.first == "layouts"

      *folders, file = relative_path_components

      controller = (folders.map { _1.camelize }.join("::") + "Controller").safe_constantize

      return false unless controller

      controller.public_instance_methods.include? file.split(".").first.to_sym
    end
  end
end
