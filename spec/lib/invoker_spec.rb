require 'spec_helper'

describe Chanko do
  shared_examples_for 'invoker' do
    let(:invoker) { Chanko::Test::Invoker.new }

    it 'run my scoped unit methods' do
      raise_chanko_exception
      mock_unit("RunTest", Chanko::Test::Invoker, {:hoge => 1})
      invoker.invoke(:run_test, :hoge)
      invoker.instance_eval { @hoge.should == 1 }
    end

    describe 'locals' do
      context 'cant find' do
        it 'raise' do
          mock_unit("LocalVariableTest")
          LocalVariableTest.class_eval do
            scope(Chanko::Test::Invoker) do
              function(:missing_locals) { missing }
            end
          end
          expect {
            invoker.invoke(:local_variable_test, :missing_locals)
          }.to raise_error(NameError)
        end

        it 'not raise when raising is repressed' do
          no_raise_chanko_exception
          mock_unit("LocalVariableTest")
          LocalVariableTest.class_eval do
            scope(Chanko::Test::Invoker) do
              function(:missing_locals) { missing }
            end
          end
          expect {
            invoker.invoke(:local_variable_test, :missing_locals)
          }.to_not raise_error(NameError)
        end
      end

      it 'skip default' do
        mock_unit("SkipDefault",  Chanko::Test::Invoker, {:hoge => {:value => 1}})
        invoker.invoke(:skip_default, :hoge) { @fuga = 1 }
        invoker.instance_eval do
          @hoge.should == 1
          @fuga.should == nil
        end
      end

      it 'run other context function' do
        mock_unit("SecondTest", :controller, :hello => { :value => "hello" })
        invoker.invoke(:second_test, :hello, :as => :controller)
        invoker.instance_eval { @hello.should == "hello" }
      end

      it 'run function when depend on unit was enabled' do
        raise_chanko_exception
        mock_unit("DependOnUnit", Chanko::Test::Invoker, { :hello => "hello" })
        mock_unit("EnabledUnit", Chanko::Test::Invoker, { :hello => "hello2"})
        invoker.invoke(:depend_on_unit, :hello, :if => :enabled_unit)
        invoker.instance_eval { @hello.should == "hello" }
      end

      it 'not run function if depend on unit is disabled' do
        no_raise_chanko_exception
        mock_unit("DependOnUnit", Chanko::Test::Invoker, { :hello => "hello" })
        mock_unit("DisabledUnit", Chanko::Test::Invoker, { :hello => {:value => "hello2"}}, :disable => true)
        invoker.invoke(:depend_on_unit, :hello, :if => :disabled_unit)
        invoker.instance_eval { @hello.should == nil }
      end

      it 'not run function if depend on unit is missing' do
        no_raise_chanko_exception
        mock_unit("DependOnUnit", Chanko::Test::Invoker, { :hello => "hello" })
        invoker.invoke(:depend_on_unit, :hello, :if => :missing_unit)
        invoker.instance_eval { @hello.should == nil }
      end

      it 'access locals' do
        mock_unit("LocalVariableTest", self.class, {:hoge => 1})
        LocalVariableTest.class_eval do
          scope(Chanko::Test::Invoker) do
            function(:set_variable) { @var = var }
          end
        end
        invoker.invoke(:local_variable_test, :set_variable, :locals => {:var => true})
        invoker.instance_eval do
          @var.should == true
        end
      end

      it 'access locals without `:locals => {}`' do
        mock_unit("LocalVariableTest", self.class, {:hoge => 1})
        LocalVariableTest.class_eval do
          scope(Chanko::Test::Invoker) do
            function(:set_variable) { @var = var }
          end
        end
        invoker.invoke(:local_variable_test, :set_variable, :var => true)
        invoker.instance_eval do
          @var.should == true
        end
      end

      it 'access nested function locals' do
        mock_unit("LocalVariableTest", self.class, {:hoge => 1})
        mock_unit("NestedLocalVariableTest", self.class, {:hoge => 1})

        LocalVariableTest.class_eval do
          scope(Chanko::Test::Invoker) do
            function(:set_variable) do
              @before = var
              invoke(:nested_local_variable_test, :set_variable, :locals => {:var => false})
              @after = var
            end
          end
        end

        NestedLocalVariableTest.class_eval do
          scope(Chanko::Test::Invoker) do
            function(:set_variable) do
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

    it 'accede to active_if symbols' do
      no_raise_chanko_exception
      mock_unit("SymbolActiveIfTest", Chanko::Test::Invoker, { :hello => "hello" })
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

      SymbolActiveIfTest.class_eval { active_if :always_true, :nondefined_symbol  }
      invoker.invoke(:symbol_active_if_test, :hello)
      invoker.instance_eval { @hello.should == nil }

      SymbolActiveIfTest.class_eval { active_if :always_true do; true; end  }
      invoker.invoke(:symbol_active_if_test, :hello)
      invoker.instance_eval { @hello.should == "hello" }
      invoker.instance_eval { @hello = nil }

      Chanko::ActiveIf.define(:symbol_active_if_test) do |context, options|
        unit = options[:unit]
        unit.name == "SymbolActiveIfTest"
      end

      SymbolActiveIfTest.class_eval do
        active_if :always_true, :symbol_active_if_test do |context, options|
          true
        end
      end
      invoker.invoke(:symbol_active_if_test, :hello)
      invoker.instance_eval { @hello.should == "hello" }
    end


    it 'set current function' do
      mock_unit("CurrentFunctionTest", Chanko::Test::Invoker, { :set_current_function => {:value => Proc.new { @current_function = __current_function}  }})
      invoker.invoke(:current_function_test, :set_current_function)
      invoker.instance_eval { @current_function.unit.name.should == "CurrentFunctionTest"}
      invoker.instance_eval { @current_function.label.should == :set_current_function}
      invoker.__current_function.should be_nil
    end

    it 'neve run function when once function aborts' do
      no_raise_chanko_exception
      mock_unit("NotRunFunctionTest", Chanko::Test::Invoker, 
        :raise => {:value => Proc.new { raise } },
        :success => {:value => Proc.new { @success = true} })

      invoker.invoke(:not_run_function_test, :raise)
      invoker.invoke(:not_run_function_test, :success)
      invoker.instance_eval { @success.should == nil }
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'invoker'
  end

  context 'without cache_classes' do before { Chanko.config.cache_classes = false }
    it_should_behave_like 'invoker'
  end
end
