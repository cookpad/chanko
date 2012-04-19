# -*- coding: utf-8 -*-
=begin
require 'spec_helper'

describe Chanko::Helper, :type => :helper do
  include Chanko::Helper
  it "hello" do
    unit(:sample).hello.should == "hello"
  end
end
=end
