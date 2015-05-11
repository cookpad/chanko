require "spec_helper"

module Chanko
  describe Invoker do
    let(:view) do
      Class.new(ActionView::Base) do
        include Chanko::Invoker
        include Chanko::Helper
        include Chanko::UnitProxyProvider
      end.new
    end

    let(:controller) do
      Class.new(ActionController::Base) do
        include Chanko::Invoker
        include Chanko::Helper
        include Chanko::UnitProxyProvider
      end.new
    end

    describe "#invoke" do
      it "invokes in the same context with receiver" do
        view.invoke(:example_unit, :self, :type => :plain).should == view
      end

      it "invokes with locals option" do
        view.invoke(:example_unit, :locals, :locals => { :key => "value" }, :type => :plain).
          should == "value"
      end

      it "invokes with falsy locals" do
        view.invoke(:example_unit, :falsy, :locals => { :key => nil }, :type => :plain).
          should == true
      end

      it "invokes with shared method" do
        view.invoke(:example_unit, :shared, :type => :plain).should == "shared args"
      end

      it "invokes with helper method in view context" do
        view.invoke(:example_unit, :helper, :type => :plain).should == "helper"
      end

      context 'when unit is referred from unit function' do
        it 'responds to method which the context responds to' do
          expect(view.invoke(:example_unit, :respond_to_helper?, type: :plain)).to eq(true)
        end
      end

      context "when invoked in view" do
        it "invokes with partial view" do
          view.invoke(:example_unit, :render, :type => :plain).should == "test\n"
        end
      end

      context "when invoked in controller" do
        it "invokes with unit views path" do
          controller.invoke(:example_unit, :render, :type => :plain).should == "test\n"
        end
      end

      context "when short-hand style args is passed" do
        it "recognizes args as locals option" do
          view.invoke(:example_unit, :locals, :key => "value").should ==
            '<div class="unit unit__example_unit unit__example_unit__locals">value</div>'
        end
      end

      context "when type is not specified" do
        it "invokes and returns result surrounded by div" do
          view.invoke(:example_unit, :test).should ==
            '<div class="unit unit__example_unit unit__example_unit__test">test</div>'
        end
      end

      context "when Config.compatible_css_class is true" do
        before do
          Config.compatible_css_class = true
        end

        it "invokes and returns result surrounded by div" do
          view.invoke(:example_unit, :test).should ==
            '<div class="extension ext_example_unit ext_example_unit-test">test</div>'
        end
      end

      context "when type is :plain" do
        it "does not surround result with html element" do
          view.invoke(:example_unit, :test, :type => :plain).should == "test"
        end
      end

      context "when the result is blank" do
        it "does not surround result with html element" do
          view.invoke(:example_unit, :blank).should == " "
        end
      end

      context "when type is :inline" do
        it "invokes and returns result surrounded by span" do
          view.invoke(:example_unit, :test, :type => :inline).should ==
            '<span class="unit unit__example_unit unit__example_unit__test">test</span>'
        end
      end

      context "when context is not a view" do
        it "does not surround result with html tag" do
          controller.invoke(:example_unit, :test).should == "test"
        end
      end

      context "when run_default is called in function" do
        it "invokes given block as a fallback" do
          controller.invoke(:example_unit, :default) { "default" }.should == "default"
        end
      end

      context "when nested run_default is called in function" do
        it "invokes given block as a fallback" do
          Chanko::Loader.load("sensitive_unit")
          expect(SensitiveUnit).to receive(:ping).once

          controller.invoke(:sensitive_unit, :outer_default) do
            "default"
          end.should eq "default"
        end

        it 'use both locals' do
          controller.invoke(:example_unit, :nesting_locals_outer, :locals => { :outer_one => "outer_one", :outer_two => "outer_two", :outer_three => "outer_three"}) do
            "default"
          end.should eq "outer_one.inner_one.outer_two.default.inner_two.outer_three"
        end

        context 'active_if is false' do
          it "invokes given block as a fallback " do
            Chanko::Loader.load("sensitive_inactive_unit")
            controller.invoke(:sensitive_inactive_unit, :outer) do
              invoke(:sensitive_inactive_unit, :inner)
            end.should eq nil
          end
        end
      end

      context "when run_default is called but no block given" do
        it "invokes given block as a fallback" do
          controller.invoke(:example_unit, :default).should == nil
        end
      end

      context "when non-existent unit is specified" do
        it "does nothing" do
          view.invoke(:non_existent_unit, :test, :type => :plain).should == nil
        end
      end

      context "when function is not found" do
        it "runs default but not handled by ExceptionHandler" do
          ExceptionHandler.should_not_receive(:handle)
          view.invoke(:example_unit, :non_existent_function) { "default" }.should == "default"
        end
      end

      context "when an error is raised in invoking" do
        context "when block is given" do
          context "when context is a view" do
            it "captures given block as a fallback" do
              view.should_receive(:capture).and_call_original
              view.invoke(:example_unit, :error) { "error" }.should == "error"
            end
          end

          context "when context is not a view" do
            it "calls given block as a fallback" do
              controller.should_not_receive(:capture)
              controller.invoke(:example_unit, :error) { "error" }.should == "error"
            end
          end
        end

        context "when no block is given" do
          it "rescues the error and does nothing" do
            view.invoke(:example_unit, :error).should == nil
          end
        end
      end
    end
  end
end
