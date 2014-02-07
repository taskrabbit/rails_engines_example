require 'spec_helper'

describe Account::User do
  fixtures :users

  let(:user) { users(:paul) }
  it "should authenticate" do
    user.authenticate("12341234").should be_true
  end
  
end
