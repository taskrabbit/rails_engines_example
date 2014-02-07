require 'fixture_builder'

FixtureBuilder.configure do |fbuilder|
  fbuilder.files_to_check += Dir["spec/*/factories/**/*.rb", "spec/support/fixture_builder.rb", "apps/*/db/seeds.rb"]

  fbuilder.factory do
    # =================================================================
    # Seeds
    # =================================================================
    load(Rails.root.join('db/seeds.rb'))

    # =================================================================
    # Account
    # =================================================================
    willy = fbuilder.name(:willy, FactoryGirl.create(:user, first_name: 'Willy', last_name: 'Watcher',  email: 'willy@example.com')).first
    paul  = fbuilder.name(:paul,  FactoryGirl.create(:user, first_name: 'Paul',  last_name: 'Poster',   email: 'paul@example.com')).first

    # =================================================================
    # Content
    # =================================================================
    post = fbuilder.name(:post, FactoryGirl.create(:post, user_id: paul.id, content: "Fixtures are cool.")).first

  end

end
