FactoryGirl.define do

  factory :post, class: Content::Post do
    user { Content::User.find(FactoryGirl.create(:user).id) }
    sequence(:content) { |n| "#{n} words here" }
  end
end
