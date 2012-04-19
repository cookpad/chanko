# -*- coding: utf-8 -*-
=begin
require 'spec_helper'

describe '<%= class_name %>Controller', :type => :controller do
  before do
    enable_unit(:<%= file_name %>)
  end

  it "success" do
    get :index
    response.should be_success
  end
end
=end
