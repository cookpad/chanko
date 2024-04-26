module Chanko
  module Generators
    class UnitGenerator < Rails::Generators::NamedBase
      ASSETS_TYPES = %w[images javascripts stylesheets]

      source_root File.expand_path("../templates", __FILE__)

      def create_unit_directory
        empty_directory(unit_directory)
      end

      def create_unit_file
        template("unit.rb.erb", "#{unit_directory}/#{file_name}.rb")
      end

      def create_views_unit_directory
        create_file("#{unit_directory}/views/.gitkeep", "")
      end

      ASSETS_TYPES.each do |type|
        define_method("create_#{type}_unit_directory") do
          create_file("#{unit_directory}/#{type}/.gitkeep", "")
        end

        define_method("create_#{type}_unit_symlink") do
          create_assets_symlink(type)
        end
      end

      def create_views_symlink
        from = "app/views/#{units_directory_name}/#{file_name}"
        to   = "../../../#{relative_unit_directory}/views"
        create_link(from, to)
      end

      private

      def create_assets_symlink(type)
        from = "app/assets/#{type}/#{units_directory_name}/#{file_name}"
        to   = "../../../../#{relative_unit_directory}/#{type}"
        create_link(from, to)
      end

      def relative_unit_directory
        Pathname.new(unit_directory).relative_path_from(Rails.root)
      end

      def unit_directory
        "#{Chanko::Config.units_directory_path}/#{file_name}"
      end

      def units_directory_name
        Chanko::Config.units_directory_path.split("/").last
      end
    end
  end
end

