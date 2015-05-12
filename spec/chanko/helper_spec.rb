require "spec_helper"

module Chanko
  describe Helper do
    describe ".define" do
      after do
        described_class.class_eval do
          remove_method :__example_unit_test rescue nil
        end
      end

      let(:view) do
        Class.new { include Chanko::Helper }.new
      end

      it "defines helper methods with special prefix" do
        described_class.define(:example_unit) do
          def test
            "test"
          end
        end
        expect(view.__example_unit_test).to eq("test")
      end
    end
  end
end
