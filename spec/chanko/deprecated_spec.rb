require "spec_helper"

module Chanko
  describe ActiveIf do
    describe "options" do
      before do
        @orig_stderr = $stderr
        $stderr = StringIO.new
      end

      after do
        $stderr = @orig_stderr
      end

      it "uses options in #new" do
        _ = ActiveIf.new foo: 'bar'
        expect($stderr.string).to match(/\b deprecated \b/xms)
      end

      it "uses #options" do
        o = ActiveIf.new
        expect(o.options.empty?).to be true
        expect($stderr.string).to match(/\b deprecated \b/xms)
      end
    end
  end
end
