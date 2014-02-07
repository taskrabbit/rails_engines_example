module Shared
  module Helper
    module Errors
      def show_object_errors(object)
        return "" if object.errors.size == 0
        render "/shared/layouts/errors", object: object
      end
    end
  end
end