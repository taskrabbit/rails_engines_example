require 'spec_helper'

describe Content::Post do
  it "should validate content" do
    Content::Post.new.should have(1).error_on(:content)
  end
end
