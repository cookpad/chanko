# encoding: UTF-8
require 'spec_helper'

describe "users/index.html.haml" do
  it "render users_path" do
    render
    rendered.should include(users_path)
  end
end
