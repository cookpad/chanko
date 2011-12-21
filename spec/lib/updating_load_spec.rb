require 'spec_helper'

describe Chanko do
  shared_examples_for 'updating load' do
    after do
      Object.send(:remove_const, 'ChankoDummy') rescue nil
      ActiveSupport::Dependencies.reset_timestamps_and_defined_classes
    end

    it 'should raise if missing related file is required' do
      expect {
        require_or_updating_load 'missing'
      }.to raise_error(LoadError)
    end

    it 'should raise if missing absolute file is required' do
      expect {
        require_or_updating_load '/missing'
      }.to raise_error(LoadError)
    end

    it 'should load from related path' do
      require_or_updating_load 'chanko_dummy'
      Object.constants.map(&:to_s).should be_include('ChankoDummy')
    end
  end

  shared_examples_for 'updating load without cache' do
    after do
      Object.send(:remove_const, 'ChankoDummy') rescue nil
      ActiveSupport::Dependencies.reset_timestamps_and_defined_classes
    end

    it 'should clear' do
      require_or_updating_load 'chanko_dummy'
      ActiveSupport::Dependencies.send(:clear_defined_classes, 'chanko_dummy')
      Object.constants.map(&:to_s).should_not be_include('ChankoDummy')
    end

    it 'should return updated status' do
      ActiveSupport::Dependencies.send(:file_updated?, 'chanko_dummy').should be_true
      require_or_updating_load 'chanko_dummy'
      ActiveSupport::Dependencies.send(:file_updated?, 'chanko_dummy').should be_false
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'updating load'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_should_behave_like 'updating load'
    it_should_behave_like 'updating load without cache'
  end
end
