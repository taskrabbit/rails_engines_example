module Shared
  module User
    class Stub < ActiveRecord::Base
      self.table_name = :users

    end
  end
end
