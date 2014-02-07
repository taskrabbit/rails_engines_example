# maps fixutres to their class names if different than defaults
# gets included by spec helper in the config block
module FixtureClassNameHelper

  extend ::ActiveSupport::Concern

  included do
    set_fixture_class({
      users: 'Account::User'
    })
  end


  def fixture(standard_method, standard_name, override_namespace = nil)
    model = send(standard_method, standard_name)


    # if the override namespace is not provided this uses the current test
    # context as a best guess for it
    if !override_namespace && described_class
      potential_namespace = described_class.name.split('::').first
      if potential_namespace.constantize.const_defined?(:Engine)
        override_namespace = potential_namespace
      end
    end

    return model unless override_namespace

    parts     = model.class.name.split('::')
    parts[0]  = override_namespace
    klass     = parts.join('::').constantize

    klass.send(:instantiate, model.attributes)
  end

end
