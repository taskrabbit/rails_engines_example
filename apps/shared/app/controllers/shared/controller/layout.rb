module Shared
  module Controller
    module Layout
      extend ::ActiveSupport::Concern

      included do
        layout 'shared/layouts/application'
        include Shared::Controller::Authentication
        include Shared::Controller::Manifests
      end
    end
  end
end
