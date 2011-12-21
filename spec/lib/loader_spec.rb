require 'spec_helper'

describe Chanko do
  shared_examples_for 'loader' do
    let(:invoker) { Chanko::Test::Invoker.new }

    it 'should get required extnames' do
      ext_mock("Invoked", Chanko::Test::Invoker, { :hello => "hello" })
      ext_mock("Requested", Chanko::Test::Invoker, { :hello => {:value => "hello"}}, :disable => true)
      invoker.invoke(:invoked, :hello)
      invoker.invoke(:requested, :hello)
      Chanko::Loader.requested_extensions.should == ["invoked", "requested"]
      Chanko::Loader.invoked_extensions.should == ["invoked"]
    end

    describe 'scope' do
      it 'should return current_scope' do
        raise_chanko_exception
        invoker = Chanko::Test::Invoker.new
        ext_mock("CallbackTest")
        ext_mock("InlineCallbackTest")

        inline_callback = Chanko::Callback.new(:hello, InlineCallbackTest) do
          Chanko::Loader.current_scope.should == 'inline_callback_test'
        end

        callback = Chanko::Callback.new(:hello, CallbackTest) do
          Chanko::Loader.current_scope.should == 'callback_test'
          inline_callback.invoke!(invoker)
          Chanko::Loader.current_scope.should == 'callback_test'
        end

        callback.invoke!(invoker)
      end
    end

    describe 'directory' do
      before do
        @_directories = Chanko::Loader.instance_variable_get("@directories")
      end
      after do
        Chanko::Loader.instance_variable_set("@directories", @_directories)
      end


      it 'should load path_file' do
        Chanko::Loader.load_path_file(fixtures_path.join('load_path_file'), '/root')
        Chanko::Loader.directories.map(&:to_s).should be_include('/path1')
        Chanko::Loader.directories.map(&:to_s).should be_include('/root/path2')
      end

      it 'should add path' do
        Chanko::Loader.add_path("/path1")
        Chanko::Loader.directories.map(&:to_s).should be_include('/path1')
      end
    end

    describe 'load' do
      it 'should load extension from file' do
        Chanko::Loader.load_extension(:load_ext)
        Chanko::Loader.size.should == 1
        Object.constants.map(&:to_s).include?(LoadExt)
        LoadExt.ancestors.should be_include(Chanko::Unit)
      end

      it 'should not notify load error when skip_raise is true' do
        Chanko::ExceptionNotifier.should_receive(:notify).exactly(1)
        Chanko::Loader.load_extension(:missing_ext, :skip_raise => true)
        Chanko::Loader.load_extension(:missing_ext1, :skip_raise => false)
      end
    end


    it 'should return jsfiles' do
      Chanko::Loader.javascripts("sample_ext").size.should == 2
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'loader'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_should_behave_like 'loader'
  end
end
