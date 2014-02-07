module Admin

  class PostSearch < ::Shared::Operation::Base

    fields  :query

    validates :query, presence: true
    attr_reader :results

    protected

    def page
      @page || 1
    end

    def perform
      return false if self.query.blank?
      @results = send("search_by_#{search_type}")
      @results = @results.order('posts.created_at DESC')
      @results = @results.page(self.page).per(20)
      @results.size > 0
    end

    # http://www.area-codes.org.uk/formatting.php
    def search_type
      case self.query.to_s
      when /^\d+$/
        :id
      else
        :content
      end
    end

    def search_by_id
      Admin::Post.where(id: self.query.to_i)
    end

    def search_by_content
      q = self.query
      Admin::Post.where("posts.content LIKE ?", "%#{q}%")
    end

  end


end
