module Shared
  module User
    module Display

      def display_name
        return "#{half_email}" if first_name.blank?
        return "#{first_name}" if last_name.blank?
        return "#{first_name} #{last_name[0,1]}."
      end

      def full_name
        return "#{email}" if email.present? && first_name.blank?
        return "#{first_name} #{last_name}" unless first_name.blank? || last_name.blank?
        return "#{first_name}" unless first.blank?
        return "#{last_name}" unless last.blank?
        return ""
      end

      private

      def half_email
        return "" if email.blank?
        index = email.index('@')
        return "" if index.nil? || index.to_i.zero?
        return email[0, index.to_i]
      end
      
    end
  end
end
