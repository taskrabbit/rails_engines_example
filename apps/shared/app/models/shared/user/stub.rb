module Shared
  module User
    class Stub < ActiveRecord::Base
      self.table_name = :users

      include Shared::Model::ReadOnly

    end
  end
end
