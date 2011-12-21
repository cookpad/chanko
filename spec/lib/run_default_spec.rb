# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Chanko" do
  shared_examples_for 'run default' do
    before do
      no_raise_chanko_exception
      ext_mock("RunDefaultTestExt", Chanko::Test::Invoker)

      @invoker = mock("invoker")
      @invoker.class.send(:include, Chanko::Invoker)
    end

    it 'should render default block' do
      callbacks = []
      options = {}
      callbacks << Chanko::Callback.new(:hello, RunDefaultTestExt) do
        buffer ='before_default '
        buffer << run_default
        buffer << ' after_default'
        buffer
      end
      default = Chanko::Callback.default { 'default' }
      result = @invoker.render_callbacks(callbacks, default, options)
      result.should == 'before_default default after_default'
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'run default'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_should_behave_like 'run default'
  end
end

