ENV['RAILS_ENV'] = 'test'

require_relative "../config/environment.rb"

require 'rspec/rails'

require 'rack/utils'
require 'rspec/autorun'

ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

RSpec.configure do |config|
  config.infer_base_class_for_anonymous_controllers = false
  config.order = "random"

  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.before(:each) do
    Rails.cache.clear rescue nil

    Time.zone = 'UTC'
  end

  # define the factories
  require_relative 'support/test_after_commit'
  require 'factory_girl'
  require 'forgery'

  Dir[Rails.root.join("spec/*/factories/**/*.rb")].each  { |f| require f }

  # configure fixture options
  config.fixture_path               = "#{Rails.root}/spec/fixtures/"
  config.use_transactional_fixtures = true

  # fixup any namespace weirdness
  require_relative 'support/fixture_class_name_helper'
  config.include ::FixtureClassNameHelper

  # build the fixtures
  require_relative 'support/fixture_builder'
end
