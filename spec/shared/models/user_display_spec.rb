require 'spec_helper'

module UserDisplayTest
  class User < ActiveRecord::Base
    self.table_name = :users
    include Shared::User::Display
  end
end

describe Shared::User::Display do
  fixtures :users

  let(:user) { fixture(:users, :paul, UserDisplayTest) }
  it "should calculate display names" do
    user.class.name.should == "UserDisplayTest::User"
    user.display_name.should == "Paul P."
    user.full_name.should == "Paul Poster"

    user.first_name = nil
    user.last_name = nil
    user.display_name.should == "paul"
  end
end
