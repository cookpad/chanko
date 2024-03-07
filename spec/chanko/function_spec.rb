require "spec_helper"

module Chanko
  describe Function do
    let(:unit) do
      Loader.load(:example_unit)
    end

    def rails5_action_view_instance
      klass = Class.new(ActionView::Base) do
        def current_unit
          units.last
        end

        def units
          @units ||= []
        end
      end
      klass.new
    end

    def rails6_action_view_instance
      klass = Class.new(ActionView::Base.with_empty_template_cache) do
        def current_unit
          units.last
        end

        def units
          @units ||= []
        end
      end
      klass.with_view_paths([], {}, nil)
    end

    let(:context) do
      case Rails::VERSION::MAJOR
      when 5
        rails5_action_view_instance
      when 6
        rails6_action_view_instance
      end
    end

    let(:options) do
      { :type => :plain }
    end

    describe ".invoke" do
      it "invokes block with given context and stacked unit" do
        expect(described_class.new(unit, :label) { current_unit }.invoke(context, options)).to eq(unit)
      end
    end
  end
end
