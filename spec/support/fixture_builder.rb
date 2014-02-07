require 'fixture_builder'

FixtureBuilder.configure do |fbuilder|
  fbuilder.files_to_check += Dir["spec/*/factories/**/*.rb", "spec/support/fixture_builder.rb", "apps/*/db/seeds.rb"]

  fbuilder.factory do
    # =================================================================
    # Seeds
    # =================================================================
    load(Rails.root.join('db/seeds.rb'))

    paul = fbuilder.name(:paul, FactoryGirl.create(:user, first_name: 'Paul', last_name: 'Poster',  email: 'paul@example.com')).first


  end

end
