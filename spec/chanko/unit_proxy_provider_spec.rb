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
          proxy.should be_a UnitProxy
          proxy.unit.should == ExampleUnit
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
          proxy.unit.should == ExampleUnit
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
          view.should_not be_respond_to(:proxy)
          proxy = view.proxy(:example_unit)
          proxy.should be_a UnitProxy
          view.should be_respond_to(:proxy)
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
          view.should_not be_respond_to(:proxy1)
          view.should_not be_respond_to(:proxy2)
          view.proxy1(:example_unit).should be_a UnitProxy
          view.proxy2(:example_unit).should be_a UnitProxy
          view.should be_respond_to(:proxy1)
          view.should be_respond_to(:proxy2)
        end
      end
    end
  end
end
