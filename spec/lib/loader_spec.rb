require 'spec_helper'

describe Chanko do
  shared_examples_for 'loader' do
    let(:invoker) { Chanko::Test::Invoker.new }

    describe 'store requested unit names' do
      before do
        no_raise_chanko_exception
        mock_unit("Invoke", Chanko::Test::Invoker, { :hello => "hello" })
        mock_unit("Request", Chanko::Test::Invoker, { :hello => {:value => "hello"}}, :disable => true)
        mock_unit("Abort", Chanko::Test::Invoker, { :hello => {:value => Proc.new { raise }} })
        invoker.invoke(:invoke, :hello)
        invoker.invoke(:request, :hello)
        invoker.invoke(:abort, :hello)
      end

      it 'get requested unit names' do
        Chanko::Loader.requested_units.should == ["invoke", "request", "abort"]
      end

      it 'get invoked unit names' do
        Chanko::Loader.invoked_units.should == ["invoke", "abort"]
      end

      it 'get aborted unit names' do
        Chanko::Loader.aborted_units.should == ["abort"]
      end
    end

    describe 'scope' do
      it 'should return current_scope' do
        raise_chanko_exception
        invoker = Chanko::Test::Invoker.new
        mock_unit("FunctionTest")
        mock_unit("InlineFunctionTest")

        inline_function = Chanko::Function.new(:hello, InlineFunctionTest) do
          Chanko::Loader.current_scope.should == 'inline_function_test'
        end

        function = Chanko::Function.new(:hello, FunctionTest) do
          Chanko::Loader.current_scope.should == 'function_test'
          inline_function.invoke!(invoker)
          Chanko::Loader.current_scope.should == 'function_test'
        end

        function.invoke!(invoker)
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
      around(:each) do |example|
        ActiveSupport::Dependencies.reset_timestamps_and_defined_classes
        example.run
      end

      it 'should load singular name unit via file' do
        Chanko::Unit.should_receive(:clear_function_cache).with('LoadUnit')
        Chanko::Loader.load_unit(:load_unit)
        Chanko::Loader.size.should == 1
        Object.constants.map(&:to_s).should be_include('LoadUnit')
        LoadUnit.ancestors.should be_include(Chanko::Unit)
      end

      it 'should load plural name unit via file' do
        Chanko::Unit.should_receive(:clear_function_cache).with('LoadUnits')
        Chanko::Loader.load_unit(:load_units)
        Chanko::Loader.size.should == 1
        Object.constants.map(&:to_s).should be_include('LoadUnits')
        LoadUnits.ancestors.should be_include(Chanko::Unit)
      end

      it 'should not notify load error when skip_raise is true' do
        Chanko::ExceptionNotifier.should_receive(:notify).exactly(1)
        Chanko::Loader.load_unit(:missing_unit, :skip_raise => true)
        Chanko::Loader.load_unit(:missing_unit1, :skip_raise => false)
      end
    end


    it 'should return jsfiles' do
      Chanko::Loader.javascripts("sample_unit").size.should == 2
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
