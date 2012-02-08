module Chanko
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc <<-DESC
Description:
  Install chanko to your rails application.
DESC

      source_root File.expand_path("../templates", __FILE__)
      class_option :directory, :type => :string, :default => 'chanko', :description => "Chanko directory name"
      def copy_install_file
        initializer("chanko_initializer.rb") do
          <<-EOS
Chanko.config.raise = true if Rails.env.development?
Chanko::Loader.add_path(Rails.root.join('app/#{base_directory}')) if Chanko::Loader.directories.blank?
active_if_files = Pathname.glob(Rails.root.join("lib", "chanko", "active_if", "*.rb")).map(&:to_s)
Chanko::ActiveIf.files = active_if_files
          EOS
        end
      end

      def create_symbolic_link
        inside(Rails.root) do
          run("ln -ns ../app/#{base_directory} spec/#{base_directory}") if File.exists?(Rails.root.join("spec"))
          run("ln -ns ../app/#{base_directory} test/#{base_directory}") if File.exists?(Rails.root.join("test"))
        end
      end

      def create_active_if_files
        directory "active_if", "lib/chanko/active_if"
      end

      private
      def base_directory
        ENV['CHANKOS_DIRECTORY'] || options[:directory].pluralize
      end
    end
  end
end
