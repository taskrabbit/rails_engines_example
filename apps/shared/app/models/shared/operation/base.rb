# Operation
#  the base implementation of a form object.
#  the form has a set of defined fields which can be used in validations.
#  the form object responds to `submit` and invokes validations
#  if validations pass the `perform` method is invoked
#  it is the responsibility of the concrete class to implement `perform`
#
#  Example usage:
#   class SignupForm < ::Backend::Operation
#
#     fields :email, :password, :password_confirmation
#
#     validates :email, :password, :password_confirmation, presence: true
#     validates :email, confirmation: true
#
#     validate :validate_email_is_gmail
#
#     protected
#
#     # at this point, validations have already run
#     def perform
#       user = User.new(self.attributes)
#
#       unless user.save
#        return self.inherit_errors_from(user)
#       end
#
#       true
#     end
#
#     def validate_email_is_gmail
#       unless self.email.to_s =~ /@gmail\.com/
#         self.errors.add(:email, :gmail)
#         return false
#       end
#
#       true
#     end
#   end
#

module Shared
  module Operation
    class Base
      include ::ActiveModel::Model
      include ::ActiveModel::Validations::Callbacks

      class_attribute :_fields
      self._fields = []
      class_attribute :_defaults
      self._defaults = {}
      class_attribute :_error_map
      self._error_map = {}



      class << self

        # fields can be provided in the following way:
        # field :field1, :field2
        # field :field3, :field4, default: 'my default'
        # field field5: 'field5 default', field6: 'field6 default'
        def field(*fields)
          last_hash = fields.extract_options!
          options   = last_hash.slice(:default, :scope)

          fields << last_hash.except(:default, :scope)

          fields.each do |f|

            if f.is_a?(Hash)
              f.each do |k,v|
                field(k, options.merge(default: v))
              end
            else

              _field(f, options)
            end
          end

        end
        alias_method :fields, :field

        def default(pairs)
          self._defaults = self._defaults.merge(pairs)
        end
        alias_method :defaults, :default

        def error_map(hash)
          self._error_map = self._error_map.merge(hash)
        end

        def inherited(base)
          super
          base._fields ||= self._fields
          base._defaults ||= self._defaults
          base._error_map ||= self._error_map
        end

        # Allows the form to be "found" by a user id. Used by delay functionality if included.
        def find_by_id(user_id)
          ns    = self.name.split('::').first
          user  = "#{ns}::User".constantize.find(user_id)
          new(user)
        end

        protected

        def _field(field_name, options = {})
          field = [options[:scope], field_name].compact.join('_')
          self._fields += [field]

          attr_accessor field.to_sym

          default(field => options[:default]) if options[:default]
        end

      end



      attr_reader :current_user

      def initialize(current_user = nil, options = {})
        @current_user     = current_user
        @original_params  = {}
        @filtered_params  = {}

        self.class._defaults.each do |k,v|
          self.send("#{k}=", v.respond_to?(:call) ? v.call : v)
        end
      end

      # for the delay functionality (if included into concrete implementation)
      def delay_id
        self.current_user.try(:id)
      end


      def submit!(params = {})
        unless submit(params)
          # todo: create error class for this
          raise ActiveRecord::RecordInvalid.new(self)
        end
        true
      end

      # the action which should be invoked upon form submission (from the controller)
      def submit(params = {})

        @original_params = params.with_indifferent_access
        @filtered_params = filter_params(@original_params)

        apply_params(@filtered_params)

        return false unless self.valid?

        self.perform

      rescue ActiveRecord::RecordInvalid => e
        self.inherit_errors_from(e.record)
        false
      end


      protected


      # implement this in your concrete class.
      def perform
        raise NotImplementedError
      end


      #wrap execution with an active record base transaction
      def transaction
        ActiveRecord::Base.transaction do
          yield
        end
      end


      # applies the errors to the form object from the child object, optionally at the namespace provided
      def inherit_errors_from(object, namespace = nil)
        inherit_errors(object.errors, namespace)
      end


      # applies the errors in error_object to self, optionally at the namespace provided
      # returns false so failure cases can end with this invocation
      def inherit_errors(error_object, namespace = nil)
        error_object.each do |k,v|

          keys  = [k, [namespace, k].compact.join('_')]
          keys  = keys.map{|key| _error_map[key.to_sym] || key }

          match = keys.detect{|key| self.respond_to?(key) || @original_params.try(:has_key?, key) }

          if match
            errors.add(match, v, api_id: v.api_id)
          else
            errors.add(:base, error_object.full_message(k, v), api_id: v.api_id)
          end

        end

        false
      end


      # grabs the attributes that match the given namespace
      def namespaced_attributes(namespace, options = {})

        regex = namespace.is_a?(Regexp) ? namespace : (namespace.blank? ? /(.+)/ : /^#{namespace}_(.+)/)

        ActiveSupport::HashWithIndifferentAccess.new.tap do |out|
          _fields.each do |field|
            if field =~ regex
              v = send(field)
              out[$1.to_sym] = v
            end
          end
        end
      end


      # if you want to use strong parameters or something in your form object you can do so here.
      def filter_params(params)
        params
      end


      def apply_params(params, namespace = nil)
        params.each do |key, value|

          setter = [namespace, key].compact.join('_')

          if respond_to?("#{setter}=") && _fields.include?(setter)
            send("#{setter}=", value)
          elsif value.is_a?(Hash)
            apply_params(value, setter)
          end
        end
      end


      def bool(input)
        !!(input.to_s =~ /t|1|y|ok/)
      end

    end
  end
end
