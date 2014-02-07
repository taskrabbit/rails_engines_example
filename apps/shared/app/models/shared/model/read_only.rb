module Shared
  module Model
    module ReadOnly
      
      def readonly?
        true
      end

      def delete
        raise ReadOnlyRecord
      end

    end
  end
end