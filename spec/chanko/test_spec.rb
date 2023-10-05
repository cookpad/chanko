require "spec_helper"
require "chanko/test"

module Chanko
  describe Test do
    def rails5_action_view_instance
      Class.new(ActionView::Base).new
    end

    def rails_action_view_instance
      klass = Class.new(ActionView::Base.with_empty_template_cache)
      klass.with_view_paths(nil, {}, nil)
    end

    let(:view) do
      case Rails::VERSION::MAJOR
      when 5
        rails5_action_view_instance
      else
        rails_action_view_instance
      end
    end

    describe "#enable_unit" do
      it "forces to enable specified unit" do
        enable_unit(:inactive_unit)
        expect(view.invoke(:inactive_unit, :inactive, :type => :plain)).to eq("inactive")
      end
    end

    describe "#disable_unit" do
      it "forces to disable specified unit" do
        disable_unit(:example_unit)
        expect(view.invoke(:example_unit, :test)).to eq(nil)
      end
    end
  end
end
