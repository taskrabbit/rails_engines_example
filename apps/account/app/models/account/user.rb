require 'bcrypt'

module Account
  class User < ActiveRecord::Base
    self.table_name = :users

    has_secure_password

    validates :email, presence: true, uniqueness: true
    validates :first_name, :last_name, presence: true
  end
end
