require 'spec_helper'

describe Chanko do
  shared_examples_for 'unit' do
    describe 'directory' do
      before do
        Chanko::Loader.add_path('dir1')
      end

      after do
        Chanko::Loader.remove_path('dir1')
      end

      it 'should return absolute view paths' do
        chanko = ext_mock('AbsolutePathTest')
        chanko.send(:absolute_view_paths).should be_include(Rails.root.join('dir1', 'absolute_path_test', 'views').to_s)
      end
    end

    describe 'new' do
      before do
        @unit = ext_mock("ExtensionUnitTest", Chanko::Test::Invoker)
      end

      it 'should increment size' do
        Chanko::Loader.size.should == 1
      end

      it 'should get callbacks' do
        klass = self.class
        @unit.class_eval do
          scope(klass) { callback(:hello) {} }
        end

        @unit.callbacks(self, :hello).size.should == 1
      end

      describe 'try to get missing callback' do
        it 'should raise' do
          raise_chanko_exception
          expect { @unit.callbacks(self, :missing) }.to raise_error(Chanko::Exception::MissingCallback)
        end

        it 'should not raise when raising is repressed' do
          no_raise_chanko_exception
          expect { @unit.callbacks(self, :missing) }.to_not raise_error(Chanko::Exception::MissingCallback)
        end
      end
    end

    describe 'view' do
      let(:controller) { @controller =  ApplicationController.new }
      before { ext_mock("ViewPathTest")  }

      context 'attached to controller' do
        specify 'controller.view_paths includes view_paths of the extension' do
          ViewPathTest.attach(controller) do
            ViewPathTest.view_paths.each do |path|
              controller.view_paths.map(&:to_path).should be_include(path)
            end
          end
        end
      end

      context 'just after detaching from controller' do
        before do
          ViewPathTest.attach(controller) { }
        end

        specify 'controller.view_paths does not include view_paths of the extension' do
          ViewPathTest.view_paths.each do |path|
            controller.view_paths.map(&:to_path).should_not be_include(path)
          end
        end
      end

      context 'not attached to controller' do
        specify 'controller.view_paths does not include view_paths of the extension' do
          ViewPathTest.view_paths.each do |path|
            controller.view_paths.map(&:to_path).should_not be_include(path)
          end
        end
      end

      it 'should detach view path when block raised' do
        expect {
          ViewPathTest.attach(controller) { raise }
        }.to raise_error(RuntimeError)

        ViewPathTest.view_paths.each do |path|
          controller.view_paths.map(&:to_path).should_not be_include(path)
        end
      end
    end

    describe 'cache' do
      it 'should use ancestors_cache' do
        ext_mock("AncestorsCacheTest", :controller)
        ancestors = Object.ancestors
        Object.should_receive(:ancestors).exactly(1).times.and_return(ancestors)
        AncestorsCacheTest.send(:ancestors?, Object, String)
        AncestorsCacheTest.send(:ancestors?, Object, String)
      end
    end

    describe 'scope' do
      before do
        ext_mock("UnitScopeTest")
      end

      it 'should add callback to scope' do
        no_raise_chanko_exception
        ScopeTestClass = Class.new
        ScopeTestClass2 = Class.new
        UnitScopeTest.callbacks(ScopeTestClass, :cb).size.should == 0
        UnitScopeTest.callbacks(ScopeTestClass2, :cb).size.should == 0
        UnitScopeTest.class_eval do
          scope("ScopeTestClass") do
            callback(:cb) {}
          end
        end
        UnitScopeTest.callbacks(ScopeTestClass.new, :cb).size.should == 1
        UnitScopeTest.callbacks(ScopeTestClass2.new, :cb).size.should == 0
      end

      context 'specified class is missing' do
        it 'should raise' do
          expect {
            UnitScopeTest.class_eval do
              scope("MissingScopeClass") { }
            end
          }.to raise_error
        end

        it 'should not raise when raising is repressed' do
          no_raise_chanko_exception
          expect {
            UnitScopeTest.class_eval do
              scope("MissingScopeClass") { }
            end
          }.to_not raise_error
        end
      end
    end

    describe 'expand model' do
      before do
        ext_mock("UnitExpandTest")
      end

      it 'should create a models module if the modules method is called' do
        UnitExpandTest.constants.map(&:to_s).should_not be_include("Models")
        UnitExpandTest.send(:models) {}
        UnitExpandTest.constants.map(&:to_s).should be_include("Models")
      end

      it 'should create a expanding module if the expand method is called' do
        UnitExpandTest.send(:models) do
          expand("User") {}
        end
        UnitExpandTest::Models.constants.map(&:to_s).should be_include("User")
      end

      it 'should expand' do
        UnitExpandTest.send(:models) do
          expand("User") { def hello; 'hello'; end }
        end
        UnitExpandTest.expand!
        User.new.send(UnitExpandTest.expand_prefix + "hello").should == 'hello'
      end

      it 'should expand twice' do
        UnitExpandTest.send(:models) do
          expand("User") { def hello; 'hello'; end }
          expand("User") { def seeyou; 'seeyou'; end }
        end
        UnitExpandTest.expand!
        User.new.send(UnitExpandTest.expand_prefix + "hello").should == 'hello'
        User.new.send(UnitExpandTest.expand_prefix + "seeyou").should == 'seeyou'
      end

      it 'should raise error when try to expand missing object' do
        raise_chanko_exception
        expect  {
          UnitExpandTest.send(:models) do
            expand("MissingObject") { }
          end
        }.to raise_error(NameError)
      end

       it 'should not raise when raising is repressed' do
         no_raise_chanko_exception
         expect  {
          UnitExpandTest.send(:models) do
            expand("MissingObject") { }
          end
         }.to_not raise_error(NameError)
       end
    end

    describe 'active_if' do
      before do
        ext_mock("UnitActiveIfTest")
      end

      it 'should set active if' do
        UnitActiveIfTest.class_eval { active_if :always_true }
        UnitActiveIfTest.should be_active
        UnitActiveIfTest.class_eval { active_if :always_false }
        UnitActiveIfTest.should_not be_active
        UnitActiveIfTest.class_eval { active_if any(:always_false, :always_true) }
        UnitActiveIfTest.should be_active
        UnitActiveIfTest.class_eval { active_if any(:always_false, :always_false) }
        UnitActiveIfTest.should_not be_active
      end
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'unit'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_should_behave_like 'unit'
  end
end
