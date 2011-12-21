module Chanko
  class Directories
    include Enumerable
    def self.load_path_file(file, root='')
      directories = self.new
      File.readlines(file).each do |line|
        unless /\A\/.*/ =~ line
          directories.add("#{root}/#{line.chomp}")
        else
          directories.add(line.chomp)
        end
      end
      return directories
    end

    def initialize(*paths)
      @directories = paths.map {|path| Pathname.new(path) }
    end


    def add(path)
      @directories.push(Pathname.new(path))
    end

    def remove(path)
      @directories.delete_if { |directory| directory.to_s == path }
    end

    def directories
      @directories
    end
  end
end
