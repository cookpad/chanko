require 'spec_helper'

describe Chanko do
  shared_examples_for 'method proxy' do
    let(:receiver) do
      dummy_klass = Class.new
      dummy_klass.send(:include, Chanko::MethodProxy)
      dummy_klass.send(:include, Chanko::Helper)
      dummy_klass.new
    end

    let(:proxy) { receiver.unit(:proxy_test) }

    before do
      mock_unit("ProxyTest")
    end

    it 'should return unit proxy' do
      proxy.should be_kind_of(Chanko::MethodProxy::Proxy)
      proxy.unit.should == ProxyTest
    end

    it 'should run unit method' do
      receiver.should_receive(:__proxy_test__hello).and_return('hello')
      proxy.hello.should == 'hello'
    end

    it 'should return activity' do
      ProxyTest.class_eval { active_if { true } }
      proxy.should be_active
    end

    it 'should return false when raise error' do
      no_raise_chanko_exception
      ProxyTest.class_eval { active_if { raise 'aa' } }
      proxy.should_not be_active
    end

    it 'should return method name with prefix' do
      proxy.label("hoge").should == '__proxy_test__hoge'
    end

    context 'with block' do
      it 'should run block as being in the chanko unit' do
        raise_chanko_exception
        ProxyTest.class_eval do
          helpers do
            def hello; 'hello'; end
          end
        end

        receiver.instance_eval { class<<self; self; end }.class_eval { include Chanko::Helper }
        receiver.unit(:proxy_test) do |unit|
          unit.should == ProxyTest
          Chanko::Loader.current_scope.should == :proxy_test
          receiver.unit.hello.should == 'hello'
        end
      end

      it 'should raise error' do
        raise_chanko_exception
        expect {
          receiver.unit(:proxy_test) do |unit|
            raise StandardError, 'error'
          end
        }.to raise_error(StandardError, 'error')
      end

      it 'should not raise error when raise is repressed' do
        no_raise_chanko_exception
        expect {
          receiver.unit(:proxy_test) do |unit|
            raise StandardError, 'error'
          end
        }.to_not raise_error(StandardError, 'error')
      end

      it 'raise error when unit.propagates_errors is true' do
        no_raise_chanko_exception
        begin
          ProxyTest.propagates_errors = true
          expect {
            receiver.unit(:proxy_test) do |unit|
              raise StandardError, 'error'
            end
          }.to raise_error(StandardError, 'error')
        ensure
          ProxyTest.propagates_errors = false
        end
      end


    end

    context 'null proxy' do
      before do
        no_raise_chanko_exception
      end

      it 'should return null proxy when non-existent unit is specified' do
        null_proxy = receiver.unit(:missing)
        null_proxy.should be_kind_of(Chanko::MethodProxy::NullProxy)
      end

      it 'should always return nil' do
        null_proxy = receiver.unit(:missing)
        null_proxy.hoge.should be_false
      end
    end

    context 'spec' do
      it 'use stub' do
        pending('stub doesnt work')
        receiver.unit(:proxy_test).stub(:hello).and_return(1)
        receiver.unit(:proxy_test).hello.should == 1
      end
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'method proxy'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_should_behave_like 'method proxy'
  end
end
