module Admin
  class PanelController < ::Admin::ApplicationController
    class << self
      def parent_prefixes
        out = super
        if @parent_panel
          out.unshift("admin/#{@parent_panel.tableize}")
        end
        out
      end

      def parent_panel(parent)
        @parent_panel = parent.to_s.singularize
        prepend_before_filter :load_parent_object
      end
    end

    protected

    def parent_panel
      self.class.instance_variable_get("@parent_panel")
    end

    def parent_panel_class
      return nil unless parent_panel
      "Admin::#{parent_panel.classify}".constantize
    end

    def load_parent_object
      return unless parent_panel
      parent_obj = parent_panel_class.find(params["#{parent_panel}_id"])
      @parent = parent_obj
      instance_variable_set("@#{parent_panel}", @parent)
      @parent
    end
  end
end
