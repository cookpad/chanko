# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Ext" do
  before do
    raise_chanko_exception
  end

  shared_examples_for 'shared method' do
    let(:invoker) { Chanko::Test::Invoker.new }

    before do
      ext_mock("SharedMethodTestExt", Chanko::Test::Invoker)
      ext_mock("NestedSharedMethodTestExt", Chanko::Test::Invoker)

      SharedMethodTestExt.class_eval do
        shared(:shared_hello) { "shared hello" }
        shared(:raise_error) { raise Exception }
      end
    end

    it 'should add shared method' do
      SharedMethodTestExt.shared_methods.size.should == 2
    end

    it 'should use shared method' do
      callback = Chanko::Callback.new(:hello, SharedMethodTestExt) do
        @var = shared_hello
        shared_hello
      end

      callback.invoke!(invoker).should == "shared hello"
      invoker.instance_variable_get("@var").should == "shared hello"
    end

    it 'should raise error when shared method raise error' do
      callback = Chanko::Callback.new(:hello, SharedMethodTestExt) do
        raise_error
      end
      expect { callback.invoke!(invoker) }.to raise_error(Exception)
    end

    it 'should store error and skip raise if raise_extension_exception is false' do
      no_raise_chanko_exception
      callback = Chanko::Callback.new(:hello, SharedMethodTestExt) do
        raise_error
      end
      expect { callback.invoke!(invoker) }.to_not raise_error(StandardError)
      #FIXME
      #ErrorLog.should have(1).records
    end

    it 'should use nested shared method ' do
      NestedSharedMethodTestExt.class_eval do
        shared(:shared_hello) { "nested hello" }
      end

      nested_callback = Chanko::Callback.new(:hello, NestedSharedMethodTestExt) do
        @nested_var = shared_hello
      end

      callback = Chanko::Callback.new(:hello, SharedMethodTestExt) do
        @before_shared_var = shared_hello
        nested_callback.invoke!(self)
        @after_shared_var = shared_hello
      end
      callback.invoke!(invoker)

      invoker.instance_eval do
        @before_shared_var.should == 'shared hello'
        @nested_var.should == 'nested hello'
        @after_shared_var.should == 'shared hello'
      end
    end

    describe 'must not use other ext method' do
      before do
        NestedSharedMethodTestExt.class_eval do
          shared(:nested_hello) { shared_hello }
        end

        nested_callback = Chanko::Callback.new(:hello, NestedSharedMethodTestExt) do
          nested_hello
        end

        @invoker = invoker
        _invoker = @invoker
        @callback =Chanko::Callback.new(:hello, SharedMethodTestExt) do
          nested_callback.invoke!(_invoker)
        end
      end

      it 'should raise error when shared method is used from other ext' do
        expect { @callback.invoke!(@invoker) }.to raise_error(NameError, /undefined local variable or method `shared_hello'/)
      end

      it 'should store NameError log and skip to raise if raise_extension_exception is false' do
        no_raise_chanko_exception
        expect { @callback.invoke!(@invoker) }.to_not raise_error(NameError)
        #FIXME
        #ErrorLog.should have(1).records
      end
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'shared method'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_should_behave_like 'shared method'
  end
end
