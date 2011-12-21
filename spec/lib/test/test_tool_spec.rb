require 'spec_helper'

describe Chanko do
  before do
    ext_mock('MockTest')
    MockTest.class_eval { active_if {} }
  end
  let(:invoker) { Chanko::Test::Invoker.new }

  shared_examples_for 'mock' do
    it 'should use proc value' do
      ext_mock("ProcValueTest", Chanko::Test::Invoker, {:hoge => {:value => Proc.new { @var = "a" }}})
      invoker.invoke(:proc_value_test, :hoge)
      invoker.instance_variable_get("@var").should == "a"
    end

    describe 'active' do
      it 'should be activated' do
        active_ext(:mock_test)
        invoker.ext(:mock_test).should be_active
      end

      it 'should be deactivated' do
        deactive_ext(:mock_test)
        invoker.ext(:mock_test).should_not be_active
      end

      it 'should be activated with user_id' do
        user = mock("User")
        user.stub!(:id).and_return(1)
        active_ext(:mock_test, 1)
        invoker.ext(:mock_test).should be_active(:user => user)

        user2 = mock("User")
        user2.stub!(:id).and_return(2)
        invoker.ext(:mock_test).should_not be_active(:user => user2)
      end

      it 'should be deactivated with user_id' do
        user = mock("User")
        user.stub!(:id).and_return(1)
        active_ext(:mock_test, 1)
        active_ext(:mock_test, 2)
        deactive_ext(:mock_test, 1)
        invoker.ext(:mock_test).should_not be_active(:user => user)

        user2 = mock("User")
        user.stub!(:id).and_return(2)
        invoker.ext(:mock_test).should be_active(:user => user)
      end
    end
  end

  shared_examples_for 'raise_chanko_exception' do
    let(:callback) do
      Chanko::Callback.new(:hello, MockTest) { raise }
    end

    it 'should raise_exception' do
      no_raise_chanko_exception
      expect { callback.invoke!(invoker) }.to_not raise_error
    end

    it 'should not raise_exception' do
      raise_chanko_exception
      expect { callback.invoke!(invoker) }.to raise_error
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'mock'
    it_should_behave_like 'raise_chanko_exception'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_should_behave_like 'mock'
    it_should_behave_like 'raise_chanko_exception'
  end
end
