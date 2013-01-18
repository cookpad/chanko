# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Chanko" do
  shared_examples_for 'run default' do

    before do
      no_raise_chanko_exception
      mock_unit("RunDefaultTestExt", Chanko::Test::Invoker)
      mock_unit("RunNestedDefaultTestExt", Chanko::Test::Invoker)
      ::INVOKER_FOR_NESTED_RUN_DEFAULT_TEST = Chanko::Test::Invoker.new
    end

    after do
      Object.send(:remove_const, "INVOKER_FOR_NESTED_RUN_DEFAULT_TEST")
    end

    let(:invoker) { Chanko::Test::Invoker.new }

    it 'render default block via run_default method' do
      functions = []
      options = {}
      functions << Chanko::Function.new(:hello, RunDefaultTestExt) do
        buffer = 'before_default '
        buffer << run_default
        buffer << ' after_default'
        buffer
      end
      default = Chanko::Function.default { 'default' }
      result = invoker.render_functions(functions, default, options)
      result.should == 'before_default default after_default'
    end

    it 'raise exception when run_default is aborted' do
      functions = []
      options = {}
      functions << Chanko::Function.new(:hello, RunDefaultTestExt) do
        buffer = 'before_default '
        buffer << run_default
        buffer << ' after_default'
        buffer
      end
      default = Chanko::Function.default { raise }
      expect {
        invoker.render_functions(functions, default, options)
      }.to raise_error(StandardError)
    end

    describe 'nested' do
      it 'render default block via run_default' do
        function = Chanko::Function.new(:hello, RunDefaultTestExt) do
          default = Chanko::Function.default { 'inner' }
          nested_function = Chanko::Function.new(:hello, RunNestedDefaultTestExt) do
            run_default 
          end
          "#{::INVOKER_FOR_NESTED_RUN_DEFAULT_TEST.render_functions([nested_function], default, {})} #{run_default}"
        end

        default = Chanko::Function.default { 'outer' }
        result = ::INVOKER_FOR_NESTED_RUN_DEFAULT_TEST.render_functions([function], default, {})
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

