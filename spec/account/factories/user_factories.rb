FactoryGirl.define do

  factory :user, class: Account::User do
    sequence(:email) { |n| "user-#{n}-#{rand(9999)}@users.com" }
    password '12341234'
    password_confirmation '12341234'
    first_name { Forgery::Name.first_name }
    last_name  { Forgery::Name.last_name }
  end
end
