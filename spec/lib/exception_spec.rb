require 'spec_helper'

describe Chanko do
  shared_examples_for 'exception' do
    let(:invoker) { Chanko::Test::Invoker.new }
    before do
      raise_chanko_exception
    end

    it 'should raise by :exception option' do
      error = StandardError.new('error')
      expect {
        Chanko::ExceptionNotifier.notify('dummy', false, :exception => error)
      }.to raise_error(StandardError, 'error')
    end

    it 'should raise by :exception_klass option' do
      expect {
        Chanko::ExceptionNotifier.notify('error', false, :exception_klass => StandardError)
      }.to raise_error(StandardError, 'error')
    end

    it 'should raise basic error' do
      expect {
        Chanko::ExceptionNotifier.notify('error', false)
      }.to raise_error(Chanko::Exception, 'error')
    end

    context 'raise_chanko_exeption' do
      before do
        raise_chanko_exception
      end

      it 'should occour error if raise option is on' do
        expect { invoke(:missing_ext, :hoge) { @default = true } }.to raise_error(NameError)
      end

      it 'should occour missing callback error if raise option is on' do
        raise_chanko_exception
        ext_mock("MissingCallbackTest", self.class, {:hoge => {:value => 1}})
        expect { invoke(:missing_callback_test, :missing_callback) { @default = true } }.to raise_error(StandardError)
      end
    end

    context 'no_rais_chanko_exception' do
      before do
        no_raise_chanko_exception
      end

      it 'should not occour error if raise option is on' do
        invoker.invoke(:missing_ext, :hoge) { @default = true }
        invoker.instance_eval { @default.should == true }
      end

      it 'should not occour missing callback error if raise option is on' do
        ext_mock("MissingCallbackTest", Chanko::Test::Invoker, {:hoge => {:value => 1}})
        invoker.invoke(:missing_callback_test, :missing_callback) { @default = true }
        invoker.instance_eval { @default.should == true }
      end
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'exception'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_should_behave_like 'exception'
  end
end
