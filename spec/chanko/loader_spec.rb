require "spec_helper"

module Chanko
  describe Loader do
    describe ".load" do
      after do
        described_class.cache.clear
      end

      context "when existent unit name is passed" do
        it "loads unit in units directory and returns the Module" do
          expect(described_class.load(:example_unit)).to eq(ExampleUnit)
        end
      end

      context "when non-existent unit name is passed" do
        it "returns nil" do
          expect(described_class.load(:non_existent_unit)).to eq(nil)
        end
      end

      context "when loader has ever loaded specified unit" do
        it "load unit from cache" do
          expect_any_instance_of(described_class).to receive(:load_from_file).and_call_original
          described_class.load(:example_unit)
          described_class.load(:example_unit)
        end
      end

      context "when loader has ever loaded specified wrong unit" do
        before do
          described_class.cache.clear
        end

        it "load unit from cache" do
          expect_any_instance_of(described_class).to receive(:load_from_file).and_call_original
          described_class.load(:non_existent_unit)
          described_class.load(:non_existent_unit)
        end
      end
    end
  end
end
