require "spec_helper"

module Chanko
  describe Controller do
    describe ".unit_action" do
      let(:controller_class) do
        Class.new(ActionController::Base) do
          include Chanko::Controller
          unit_action(:example_unit, :test)
          unit_action(:example_unit, :foo, :bar)
          unit_action(:example_unit, :error)
          ext_action(:example_unit, :alias)

          def head(code)
            "Bad Request #{code}"
          end
        end
      end

      let(:controller) do
        controller_class.new
      end

      it "defines an action to invoke unit function" do
        expect(controller.test).to eq("test")
      end

      it "defines 2 actions at one line" do
        expect(controller.foo).to eq("foo")
        expect(controller.bar).to eq("bar")
      end

      it "is aliased with `ext_action`" do
        expect(controller.alias).to eq("alias")
      end

      context "when invoke is fallen back" do
        it "halts with 400 status code" do
          expect(controller.error).to eq("Bad Request 400")
        end
      end
    end
  end
end
