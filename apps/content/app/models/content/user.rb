module Content
  class User < ActiveRecord::Base
    self.table_name = :users
    
    include Shared::Model::ReadOnly

    has_many :posts
  end
end
