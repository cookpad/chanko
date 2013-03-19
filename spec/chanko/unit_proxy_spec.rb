require "spec_helper"

module Chanko
  describe UnitProxy do
    let(:view) do
      Class.new { include UnitProxyProvider }.new
    end

    describe "#active?" do
      it "returns activation status of unit" do
        view.unit(:example_unit).should be_active
        view.unit(:inactive_unit).should_not be_active
      end
    end

    describe "#method_missing" do
      it "calls prefixed method" do
        view.should_receive(:__example_unit_test)
        view.unit(:example_unit).test
      end
    end
  end
end
