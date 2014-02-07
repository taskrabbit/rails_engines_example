module Content
  class Post < ActiveRecord::Base
    self.table_name = :posts

    belongs_to :user, class_name: "Content::User"

    validates :user, :content, presence: true
  end
end
