require "spec_helper"
require "stringio"

module Chanko
  describe Logger do
    around do |example|
      origin, Rails.logger = Rails.logger, logger
      example.run
      Rails.logger = origin
    end

    let(:logger) do
      logger = ::Logger.new(io)
      logger.formatter = lambda {|severity, time, progname, message| message }
      logger
    end

    let(:io) do
      StringIO.new
    end

    let(:log) do
      io.string.rstrip
    end

    let(:exception) do
      exception = Exception.new("error message")
      exception.set_backtrace(20.times.map {|i| "test.rb:#{i + 1}:in `method#{i + 1}'" })
      exception
    end

    let(:lines) do
      <<-EOS.strip_heredoc.split("\n").map {|line| "  #{line}" }
        [Chanko] Exception - error message
        [Chanko]   test.rb:1:in `method1'
        [Chanko]   test.rb:2:in `method2'
        [Chanko]   test.rb:3:in `method3'
        [Chanko]   test.rb:4:in `method4'
        [Chanko]   test.rb:5:in `method5'
        [Chanko]   test.rb:6:in `method6'
        [Chanko]   test.rb:7:in `method7'
        [Chanko]   test.rb:8:in `method8'
        [Chanko]   test.rb:9:in `method9'
        [Chanko]   test.rb:10:in `method10'
      EOS
    end

    context "when Config.enable_logger is true" do
      before do
        Config.enable_logger = true
      end

      context "when given Exception" do
        it "parses and logs it" do
          described_class.debug(exception)
          expect(log).to eq(lines.join("\n"))
        end

        context "when Config.backtrace_limit is configured" do
          before do
            Config.backtrace_limit = 5
          end

          it "prints backtrace up to configured depth" do
            described_class.debug(exception)
            expect(log).to eq(lines[0..5].join("\n"))
          end
        end
      end

      context "when given String" do
        it "adds prefix" do
          described_class.debug("test")
          expect(log).to eq("  [Chanko] test")
        end
      end
    end

    context "when Config.enable_logger is false" do
      before do
        Config.enable_logger = false
      end

      it "logs nothing" do
        described_class.debug("test")
        expect(log).to eq("")
      end
    end

    context "when Rails.logger is nil" do
      before do
        allow(Rails).to receive(:logger)
      end

      it "does notihng" do
        expect { described_class.debug(exception) }.not_to raise_error
      end
    end
  end
end
