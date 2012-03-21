# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Chanko" do
  shared_examples_for 'run default' do

    before do
      no_raise_chanko_exception
      ext_mock("RunDefaultTestExt", Chanko::Test::Invoker)
      ext_mock("RunNestedDefaultTestExt", Chanko::Test::Invoker)
      ::INVOKER_FOR_NESTED_RUN_DEFAULT_TEST = Chanko::Test::Invoker.new
    end

    after do
      Object.send(:remove_const, "INVOKER_FOR_NESTED_RUN_DEFAULT_TEST")
    end

    let(:invoker) { Chanko::Test::Invoker.new }

    it 'render default block via run_default method' do
      callbacks = []
      options = {}
      callbacks << Chanko::Callback.new(:hello, RunDefaultTestExt) do
        buffer ='before_default '
        buffer << run_default
        buffer << ' after_default'
        buffer
      end
      default = Chanko::Callback.default { 'default' }
      result = invoker.render_callbacks(callbacks, default, options)
      result.should == 'before_default default after_default'
    end

    describe 'nested' do
      it 'render default block via run_default' do
        callback = Chanko::Callback.new(:hello, RunDefaultTestExt) do
          default = Chanko::Callback.default { 'inner' }
          nested_callback = Chanko::Callback.new(:hello, RunNestedDefaultTestExt) do
            run_default 
          end
          "#{::INVOKER_FOR_NESTED_RUN_DEFAULT_TEST.render_callbacks([nested_callback], default, {})} #{run_default}"
        end

        default = Chanko::Callback.default { 'outer' }
        result = ::INVOKER_FOR_NESTED_RUN_DEFAULT_TEST.render_callbacks([callback], default, {})
        result.should == 'inner outer'
      end
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

