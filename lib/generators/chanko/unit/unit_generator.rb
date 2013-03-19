module Chanko
  module Generators
    class UnitGenerator < Rails::Generators::NamedBase
      ASSETS_TYPES = %w[images javascripts stylesheets]

      source_root File.expand_path("../templates", __FILE__)

      def create_unit_directory
        empty_directory(directory)
      end

      def create_unit_file
        template("unit.rb.erb", "#{directory}/#{file_name}.rb")
      end

      def create_views_directory
        create_file("#{directory}/views/.gitkeep", "")
      end

      ASSETS_TYPES.each do |type|
        define_method("create_#{type}_directory") do
          create_file("#{directory}/#{type}/.gitkeep", "")
        end
      end

      ASSETS_TYPES.each do |type|
        define_method("create_#{type}_symlink") do
          create_assets_symlink(type)
        end
      end

      private

      def create_assets_symlink(type)
        from = "app/assets/#{type}/#{directory_name}/#{file_name}"
        to   = "../../../../#{directory}/#{type}"
        create_link(from, to)
      end

      def directory
        "#{Chanko::Config.units_directory_path}/#{file_name}"
      end

      def directory_name
        Chanko::Config.units_directory_path.split("/").last
      end
    end
  end
end
