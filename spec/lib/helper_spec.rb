require 'spec_helper'

describe Chanko do
  shared_examples_for 'helper' do
    it 'should regist' do
      Chanko::Helper.register('foo') do
        def bar; 'bar'; end
      end
      Chanko::Helper.instance_methods(false).map(&:to_s).should be_include(Chanko::Unit.unit_method_name('foo', 'bar'))
    end

    it 'should remove' do
      Chanko::Helper.register('foo') do
        def bar; 'bar'; end
      end
      Chanko::Helper.register('foo') {}
      Chanko::Helper.instance_methods(false).map(&:to_s).should_not be_include(Chanko::Unit.unit_method_name('foo', 'bar'))
    end

    it 'should overwrite invoke method' do
      c = Class.new
      c.send(:include, Chanko::Invoker)
      c.send(:include, Chanko::Helper)
      instance = c.new
      instance.should_receive(:invoke_without_helper).with(anything, anything, hash_including(:as => :view))
      instance.invoke(:noname, :noname)
    end

    it 'should use' do
      ext_mock("HelperTest")
      Chanko::Helper.register('HelperTest') do
        def bar; 'bar'; end
      end

      instance = Class.new.tap do |klass|
        klass.send(:include, Chanko::MethodProxy)
        klass.send(:include, Chanko::Helper)
      end.new

      instance.ext(:helper_test).bar.should == 'bar'
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'helper'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_should_behave_like 'helper'
  end
end
