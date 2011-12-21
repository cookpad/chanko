require 'spec_helper'

describe Chanko::Loader do
  shared_examples_for 'directories' do
    it 'should init' do
      directories = Chanko::Directories.new("/root_dir")
      directories.directories.map(&:to_s).should be_include('/root_dir')
    end

    it 'should add' do
      directories = Chanko::Directories.new("/root_dir")
      directories.add('/dir1')
      directories.add('/dir2')
      directories.directories.map(&:to_s).should be_include('/dir1')
      directories.directories.map(&:to_s).should be_include('/dir2')
    end

    it 'should load file' do
      directories = Chanko::Directories.load_path_file(fixtures_path.join('load_path_file'), '/root')
      directories.directories.map(&:to_s).should be_include('/path1')
      directories.directories.map(&:to_s).should be_include('/root/path2')
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'directories'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_should_behave_like 'directories'
  end
end
