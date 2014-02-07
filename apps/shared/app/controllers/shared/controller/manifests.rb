module Shared
  module Controller
    module Manifests
      extend ::ActiveSupport::Concern

      included do
        helper Shared::Controller::Manifests::Helper
        helper_method :manifests_registered
      end

      module Helper
        def render_manifests(type)
          out = []
          
          manifests_registered(type).uniq.each do |manifest|
            case type
            when 'js'
              out << javascript_include_tag(manifest)
            when 'css'
              out << stylesheet_link_tag(manifest)
            end
          end
          out.join("\n").html_safe
        end
      end

      def manifests_registered(type)
        self.class.manifests_registered(type)
      end

      module ClassMethods
        def manifests_registered(type)
          case type
          when 'js'
            @js_manifests_registered  ||= []
          when 'css'
            @css_manifests_registered ||= []
          end
        end

        def manifests(*args)
          @js_manifests_registered  ||= []
          @css_manifests_registered ||= []

          args.each do |manifest|
            engine = self.name.split("::").first.underscore
            file = "#{engine}/manifests/#{manifest}"
            @js_manifests_registered  << file if Rails.application.assets.find_asset("#{file}.js").present?
            @css_manifests_registered << file if Rails.application.assets.find_asset("#{file}.css").present?
          end
        end
        alias :manifest :manifests
      end
    end
  end
end















