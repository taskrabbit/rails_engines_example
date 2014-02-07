module Admin

  class UserSearch < ::Shared::Operation::Base

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
      @results = @results.order('users.updated_at DESC')
      @results = @results.page(self.page).per(20)
      @results.size > 0
    end

    # http://www.area-codes.org.uk/formatting.php
    def search_type
      case self.query.to_s
      when /^.+@.+\..+{2,3}$/
        :email
      when /^\d+$/
        :id
      else
        :name
      end
    end

    def search_by_email
      Admin::User.where(email: self.query)
    end

    def search_by_id
      Admin::User.where(id: self.query.to_i)
    end

    def search_by_name
      q = self.query.split(" ")
      Admin::User.where("users.first_name LIKE ? OR users.last_name LIKE ?", "%#{q[0]}%", "%#{q[-1]}%")
    end

  end


end
