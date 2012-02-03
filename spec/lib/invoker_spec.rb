require 'spec_helper'

describe Chanko do
  shared_examples_for 'invoker' do
    let(:invoker) { Chanko::Test::Invoker.new }

    it 'should run my scoped ext methods' do
      raise_chanko_exception
      ext_mock("RunTest", Chanko::Test::Invoker, {:hoge => 1})
      invoker.invoke(:run_test, :hoge)
      invoker.instance_eval { @hoge.should == 1 }
    end

    describe 'locals' do
      context 'cant find' do
        it 'should raise' do
          ext_mock("LocalVariableTest")
          LocalVariableTest.class_eval do
            scope(Chanko::Test::Invoker) do
              callback(:missing_locals) { missing }
            end
          end
          expect {
            invoker.invoke(:local_variable_test, :missing_locals)
          }.to raise_error(NameError)
        end

        it 'should not raise when raising is repressed' do
          no_raise_chanko_exception
          ext_mock("LocalVariableTest")
          LocalVariableTest.class_eval do
            scope(Chanko::Test::Invoker) do
              callback(:missing_locals) { missing }
            end
          end
          expect {
            invoker.invoke(:local_variable_test, :missing_locals)
          }.to_not raise_error(NameError)
        end
      end

      it 'should skip default' do
        ext_mock("SkipDefault",  Chanko::Test::Invoker, {:hoge => {:value => 1}})
        invoker.invoke(:skip_default, :hoge) { @fuga = 1 }
        invoker.instance_eval do
          @hoge.should == 1
          @fuga.should == nil
        end
      end


      it 'should run first enabled extension' do
        ext_mock("FirstTest", Chanko::Test::Invoker, :hello => { :value => Proc.new { run_default; @hello = "hello"} })
        ext_mock("SecondTest", Chanko::Test::Invoker, :goodbye => { :value => "goodbye" })
        invoker.invoke([:first_test, :hello], [:second_test, :hello]) { @default1 = 1 }
        invoker.instance_eval do
          @hello.should == "hello"
          @default1.should == 1
          @hello = nil
        end
        Chanko::Unit.clear_cache!
        FirstTest.class_eval do
          active_if { |context, options| false }
        end
        invoker.invoke([:first_test, :hello], [:second_test, :goodbye]) { @default2 = 2}
        invoker.instance_eval do
          @goodbye.should == "goodbye"
          @hello.should == nil
          @default2.should == nil
        end
      end

      it 'should run other context callback' do
        ext_mock("SecondTest", :controller, :hello => { :value => "hello" })
        invoker.invoke(:second_test, :hello, :as => :controller)
        invoker.instance_eval { @hello.should == "hello" }
      end


      it 'should run callback when depend on extension was enabled' do
        raise_chanko_exception
        ext_mock("DependOnExt", Chanko::Test::Invoker, { :hello => "hello" })
        ext_mock("EnabledExt", Chanko::Test::Invoker, { :hello => "hello2"})
        invoker.invoke(:depend_on_ext, :hello, :if => :enabled_ext)
        invoker.instance_eval { @hello.should == "hello" }
      end

      it 'should not run callback if depend on extension is disabled' do
        no_raise_chanko_exception
        ext_mock("DependOnExt", Chanko::Test::Invoker, { :hello => "hello" })
        ext_mock("DisabledExt", Chanko::Test::Invoker, { :hello => {:value => "hello2"}}, :disable => true)
        invoker.invoke(:depend_on_ext, :hello, :if => :disabled_ext)
        invoker.instance_eval { @hello.should == nil }
      end

      it 'should not run callback if depend on extension is missing' do
        no_raise_chanko_exception
        ext_mock("DependOnExt", Chanko::Test::Invoker, { :hello => "hello" })
        invoker.invoke(:depend_on_ext, :hello, :if => :missing_extension)
        invoker.instance_eval { @hello.should == nil }
      end

      it 'should access locals' do
        ext_mock("LocalVariableTest", self.class, {:hoge => 1})
        LocalVariableTest.class_eval do
          scope(Chanko::Test::Invoker) do
            callback(:set_variable) { @var = var }
          end
        end
        invoker.invoke(:local_variable_test, :set_variable, :locals => {:var => true})
        invoker.instance_eval do
          @var.should == true
        end
      end

      it 'should access nested locals' do
        ext_mock("LocalVariableTest", self.class, {:hoge => 1})
        ext_mock("NestedLocalVariableTest", self.class, {:hoge => 1})

        LocalVariableTest.class_eval do
          scope(Chanko::Test::Invoker) do
            callback(:set_variable) do
              @before = var
              invoke(:nested_local_variable_test, :set_variable, :locals => {:var => false})
              @after = var
            end
          end
        end

        NestedLocalVariableTest.class_eval do
          scope(Chanko::Test::Invoker) do
            callback(:set_variable) do
              @nested = var
            end
          end
        end

        invoker.invoke(:local_variable_test, :set_variable, :locals => {:var => true})
        invoker.instance_eval do
          @before.should == true
          @after.should == true
          @nested.should == false
        end
      end
    end

    it 'should acceed to active_if symbols' do
      no_raise_chanko_exception
      ext_mock("SymbolActiveIfTest", Chanko::Test::Invoker, { :hello => "hello" })
      SymbolActiveIfTest.class_eval { active_if :always_false }
      invoker.invoke(:symbol_active_if_test, :hello)
      @hello.should == nil

      SymbolActiveIfTest.class_eval { active_if :always_true }
      invoker.invoke(:symbol_active_if_test, :hello)
      invoker.instance_eval { @hello.should == 'hello' }
      invoker.instance_eval { @hello = nil }

      SymbolActiveIfTest.class_eval { active_if :always_true, :always_false }
      invoker.invoke(:symbol_active_if_test, :hello)
      invoker.instance_eval { @hello.should == nil }

      SymbolActiveIfTest.class_eval { active_if :always_true do; false; end  }
      invoker.invoke(:symbol_active_if_test, :hello)
      invoker.instance_eval { @hello.should == nil }

      SymbolActiveIfTest.class_eval { active_if :always_true, :always_false do; true; end  }
      invoker.invoke(:symbol_active_if_test, :hello)
      invoker.instance_eval { @hello.should == nil }

      #FIXME
      #::ErrorLog.count.should == 0
      SymbolActiveIfTest.class_eval { active_if :always_true, :nondefined_symbol  }
      invoker.invoke(:symbol_active_if_test, :hello)
      invoker.instance_eval { @hello.should == nil }
      #FIXME
      #::ErrorLog.count.should == 1

      SymbolActiveIfTest.class_eval { active_if :always_true do; true; end  }
      invoker.invoke(:symbol_active_if_test, :hello)
      invoker.instance_eval { @hello.should == "hello" }
      invoker.instance_eval { @hello = nil }

      Chanko::ActiveIf.define(:symbol_active_if_test) do |context, options|
        ext = options[:ext]
        ext.name == "SymbolActiveIfTest"
      end

      SymbolActiveIfTest.class_eval do
        active_if :always_true, :symbol_active_if_test do |context, options|
          true
        end
      end
      invoker.invoke(:symbol_active_if_test, :hello)
      invoker.instance_eval { @hello.should == "hello" }
    end


    it 'should set current callback' do
      ext_mock("CurrentCallbackTest", Chanko::Test::Invoker, { :set_current_callback => {:value => Proc.new { @current_callback = __current_callback}  }})
      invoker.invoke(:current_callback_test, :set_current_callback)
      invoker.instance_eval { @current_callback.ext.name.should == "CurrentCallbackTest"}
      invoker.instance_eval { @current_callback.label.should == :set_current_callback}
      invoker.__current_callback.should be_nil
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'invoker'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_should_behave_like 'invoker'
  end
end
