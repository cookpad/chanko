require "spec_helper"

module Chanko
  describe UnitProxy do
    let(:view) do
      Class.new { include UnitProxyProvider }.new
    end

    describe "#active?" do
      it "returns activation status of unit" do
        expect(view.unit(:example_unit)).to be_active
        expect(view.unit(:inactive_unit)).not_to be_active
      end
    end

    describe "#method_missing" do
      it "calls prefixed method" do
        expect(view).to receive(:__example_unit_test)
        view.unit(:example_unit).test
      end
    end
  end
end
