require "spec_helper"

module Chanko
  module Unit
    describe ScopeFinder do
      describe ".find(identifier)" do
        context "when identifier is a class" do
          it "returns identifier with no change" do
            identifier = ActionView::Base
            expect(described_class.find(identifier)).to eq(ActionView::Base)
          end
        end

        context "when identifier is a reserved label" do
          it "returns reserved class for that" do
            identifier = :view
            expect(described_class.find(identifier)).to eq(ActionView::Base)
          end
        end

        context "when identifier is a string that means a class" do
          it "returns class of that string" do
            identifier = "ActionView::Base"
            expect(described_class.find(identifier)).to eq(ActionView::Base)
          end
        end

        context "when no class is found" do
          it "returns nil" do
            identifier = "Non::Existent::Class"
            expect(described_class.find(identifier)).to eq(nil)
          end
        end
      end
    end
  end
end
