require "spec_helper"

module Chanko
  describe Function do
    let(:unit) do
      Loader.load(:example_unit)
    end

    let(:context) do
      Class.new(ActionView::Base) do
        include Chanko::Invoker

        def current_unit
          units.last
        end

        def units
          @units ||= []
        end

        def path
          view_paths.first.to_s
        end
      end.new
    end

    let(:options) do
      { :type => :plain }
    end

    describe ".invoke" do
      it "invokes block with given context and stacked unit" do
        described_class.new(unit, :label) { current_unit }.invoke(context, options).should == unit
      end


      context "when context is a view" do
        it "invokes with unit's view path" do
          described_class.new(unit, :label) { path }.invoke(context, options).should == unit.view_path
        end
      end
    end
  end
end
