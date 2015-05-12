require "spec_helper"

module Chanko
  describe ActiveIf do
    around do |example|
      origin, $stderr = $stderr, StringIO.new
      example.run
      $stderr = origin
    end

    describe ".new" do
      context "with option arguments" do
        it "prints warning message on standard error output" do
          ActiveIf.new(foo: "bar")
          expect($stderr.string).to match(/\Aoptions in ActiveIf#new are deprecated and are never used at #{__FILE__}/)
        end
      end
    end

    describe "#options" do
      it "prints warning message on standard error output" do
        ActiveIf.new.options
        expect($stderr.string).to match(/\AActiveIf#options is deprecated and is never used at #{__FILE__}/)
      end
    end
  end
end
