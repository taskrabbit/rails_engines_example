require 'spec_helper'

describe Content::Post do
  fixtures :users

  it "should validate content" do
    Content::Post.new.should have(1).error_on(:content)
  end

  it "should be associated with a user" do
    user = fixture(:users, :willy, Content)
    post = Content::Post.new(content: "words")
    post.user = user
    post.save.should == true
    user.posts.count.should == 1
  end

end
