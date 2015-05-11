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

    let(:context_without_view_paths) do
      Class.new do
        include Chanko::Invoker

        def units
          @units ||= []
        end
      end.new
    end

    let(:options) do
      { :type => :plain }
    end

    describe ".invoke" do
      it "invokes block with given context and stacked unit" do
        expect(described_class.new(unit, :label) { current_unit }.invoke(context, options)).to eq(unit)
      end

      context "when context is a view" do
        it "invokes with unit's view path" do
          expect(described_class.new(unit, :label) { path }.invoke(context, options)).to eq(unit.view_path)
        end
      end

      context "when context does not have view_paths" do
        it "invokes successfully" do
          expect(described_class.new(unit, :label) { "test" }.
            invoke(context_without_view_paths, options)).to eq("test")
        end
      end
    end
  end
end
