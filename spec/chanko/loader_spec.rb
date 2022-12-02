require "spec_helper"

module Chanko
  describe Loader do
    describe ".load" do
      after do
        Chanko::Loader.cache.clear
      end

      context "when existent unit name is passed" do
        it "loads unit in units directory and returns the Module" do
          expect(Chanko::Loader.load(:example_unit)).to eq(ExampleUnit)
        end
      end

      context "when non-existent unit name is passed" do
        it "returns nil" do
          expect(Chanko::Loader.load(:non_existent_unit)).to eq(false)
        end
      end

      context "when loader has ever loaded specified unit" do
        it "load unit from cache", classic: true do
          expect(Chanko::Loader::ClassicLoader).to receive(:load_from_cache).twice.and_call_original
          expect(Chanko::Loader::ClassicLoader).to receive(:save_to_cache).with(anything, ExampleUnit).and_call_original
          expect(Chanko::Loader.load(:example_unit)).to eq(ExampleUnit)
          expect(Chanko::Loader.load(:example_unit)).to eq(ExampleUnit)
        end
      end

      context "when loader has ever loaded specified wrong unit" do
        before do
          Chanko::Loader.cache.clear
        end

        it "load unit from cache", classic: true do
          expect(Chanko::Loader::ClassicLoader).to receive(:load_from_cache).twice.and_call_original
          expect(Chanko::Loader::ClassicLoader).to receive(:save_to_cache).with(anything, false).and_call_original
          expect(Chanko::Loader.load(:non_existent_unit)).to eq(false)
          expect(Chanko::Loader.load(:non_existent_unit)).to eq(false)
        end
      end
    end
  end
end
