require "spec_helper"

module Chanko
  describe UnitProxyProvider do
    let(:view) do
      Class.new { include Chanko::UnitProxyProvider }.new
    end

    describe "#unit" do
      context "when given unit name" do
        it "returns proxy for specified unit" do
          proxy = view.unit(:example_unit)
          expect(proxy).to be_a UnitProxy
          expect(proxy.unit).to eq(ExampleUnit)
        end
      end

      context "when given no unit name" do
        before do
          Function.units << Loader.load(:example_unit)
        end

        after do
          Function.units.pop
        end

        it "returns proxy for the top unit of current unit stack" do
          proxy = view.unit
          expect(proxy.unit).to eq(ExampleUnit)
        end
      end

      context "when Config.proxy_method_name is configured" do
        around do |example|
          origin, Config.proxy_method_name = Config.proxy_method_name, :proxy
          described_class.class_eval { remove_method origin } if view.respond_to?(origin)
          example.run
          described_class.class_eval { remove_method :proxy }
        end

        it "change this method name with it" do
          expect(view).not_to be_respond_to(:proxy)
          proxy = view.proxy(:example_unit)
          expect(proxy).to be_a UnitProxy
          expect(view).to be_respond_to(:proxy)
        end
      end

      context "when Config.proxy_method_name is configured as Array" do
        around do |example|
          origin, Config.proxy_method_name = Config.proxy_method_name, [:proxy1, :proxy2]
          described_class.class_eval { remove_method origin } if view.respond_to?(origin)
          example.run
          described_class.class_eval { remove_method :proxy1, :proxy2 }
        end

        it "change this method name with it" do
          expect(view).not_to be_respond_to(:proxy1)
          expect(view).not_to be_respond_to(:proxy2)
          expect(view.proxy1(:example_unit)).to be_a UnitProxy
          expect(view.proxy2(:example_unit)).to be_a UnitProxy
          expect(view).to be_respond_to(:proxy1)
          expect(view).to be_respond_to(:proxy2)
        end
      end
    end
  end
end
