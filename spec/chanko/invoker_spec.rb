require "spec_helper"

module Chanko
  describe Invoker do
    let(:view) do
      controller.helpers
    end

    let(:controller) do
      Class.new(ActionController::Base).new
    end

    describe "#invoke" do
      it "invokes in the same context with receiver" do
        expect(view.invoke(:example_unit, :self, :type => :plain)).to eq(view)
      end

      it "invokes with locals option" do
        expect(view.invoke(:example_unit, :locals, :locals => { :key => "value" }, :type => :plain)).
          to eq("value")
      end

      it "invokes with falsy locals" do
        expect(view.invoke(:example_unit, :falsy, :locals => { :key => nil }, :type => :plain)).
          to eq(true)
      end

      it "invokes with shared method" do
        expect(view.invoke(:example_unit, :shared, :type => :plain)).to eq("shared args")
      end

      it "invokes with helper method in view context" do
        expect(view.invoke(:example_unit, :helper, :type => :plain)).to eq("helper")
      end

      context 'when unit is referred from unit function' do
        it 'responds to method which the context responds to' do
          expect(view.invoke(:example_unit, :respond_to_helper?, type: :plain)).to eq(true)
        end
      end

      context "when invoked in view" do
        it "invokes with partial view" do
          expect(view.invoke(:example_unit, :render, :type => :plain)).to eq("test\n")
        end
      end

      context "when invoked in controller" do
        it "invokes with unit views path" do
          expect(controller.invoke(:example_unit, :render, :type => :plain)).to eq("test\n")
        end
      end

      context "when short-hand style args is passed" do
        it "recognizes args as locals option" do
          expect(view.invoke(:example_unit, :locals, :key => "value")).to eq(
            '<div class="unit unit__example_unit unit__example_unit__locals">value</div>'
          )
        end
      end

      context "when type is not specified" do
        it "invokes and returns result surrounded by div" do
          expect(view.invoke(:example_unit, :test)).to eq(
            '<div class="unit unit__example_unit unit__example_unit__test">test</div>'
          )
        end
      end

      context "when Config.compatible_css_class is true" do
        before do
          Config.compatible_css_class = true
        end

        it "invokes and returns result surrounded by div" do
          expect(view.invoke(:example_unit, :test)).to eq(
            '<div class="extension ext_example_unit ext_example_unit-test">test</div>'
          )
        end
      end

      context "when type is :plain" do
        it "does not surround result with html element" do
          expect(view.invoke(:example_unit, :test, :type => :plain)).to eq("test")
        end
      end

      context "when the result is blank" do
        it "does not surround result with html element" do
          expect(view.invoke(:example_unit, :blank)).to eq(" ")
        end
      end

      context "when type is :inline" do
        it "invokes and returns result surrounded by span" do
          expect(view.invoke(:example_unit, :test, :type => :inline)).to eq(
            '<span class="unit unit__example_unit unit__example_unit__test">test</span>'
          )
        end
      end

      context "when context is not a view" do
        it "does not surround result with html tag" do
          expect(controller.invoke(:example_unit, :test)).to eq("test")
        end
      end

      context "when run_default is called in function" do
        it "invokes given block as a fallback" do
          expect(controller.invoke(:example_unit, :default) { "default" }).to eq("default")
        end
      end

      context "when nested run_default is called in function" do
        it "invokes given block as a fallback" do
          Chanko::Loader.load("sensitive_unit")
          expect(SensitiveUnit).to receive(:ping).once

          expect(controller.invoke(:sensitive_unit, :outer_default) do
            "default"
          end).to eq "default"
        end

        it 'use both locals' do
          expect(controller.invoke(:example_unit, :nesting_locals_outer, :locals => { :outer_one => "outer_one", :outer_two => "outer_two", :outer_three => "outer_three"}) do
            "default"
          end).to eq "outer_one.inner_one.outer_two.default.inner_two.outer_three"
        end

        context 'active_if is false' do
          it "invokes given block as a fallback " do
            Chanko::Loader.load("sensitive_inactive_unit")
            expect(controller.invoke(:sensitive_inactive_unit, :outer) { invoke(:sensitive_inactive_unit, :inner) }).to eq(nil)
          end
        end
      end

      context "when run_default is called but no block given" do
        it "invokes given block as a fallback" do
          expect(controller.invoke(:example_unit, :default)).to eq(nil)
        end
      end

      context "when non-existent unit is specified" do
        it "does nothing" do
          expect(view.invoke(:non_existent_unit, :test, :type => :plain)).to eq(nil)
        end
      end

      context "when function is not found" do
        it "runs default but not handled by ExceptionHandler" do
          expect(ExceptionHandler).not_to receive(:handle)
          expect(view.invoke(:example_unit, :non_existent_function) { "default" }).to eq("default")
        end
      end

      context "when an error is raised in invoking" do
        context "when block is given" do
          context "when context is a view" do
            it "captures given block as a fallback" do
              expect(view).to receive(:capture).and_call_original
              expect(view.invoke(:example_unit, :error) { "error" }).to eq("error")
            end
          end

          context "when context is not a view" do
            it "calls given block as a fallback" do
              expect(controller).not_to receive(:capture)
              expect(controller.invoke(:example_unit, :error) { "error" }).to eq("error")
            end
          end
        end

        context "when no block is given" do
          it "rescues the error and does nothing" do
            expect(view.invoke(:example_unit, :error)).to eq(nil)
          end
        end
      end
    end
  end
end
