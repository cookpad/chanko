class ChankoGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)
  argument :models, :type => :array, :default => [], :banner => "model model"
  class_option :template, :type => :string, :description => "Chanko template directory name"
  class_option :directory, :type => :string, :description => "Chanko directory name"
  class_option :scss, :type => :boolean, :default => true, :description => "Generate a template SCSS file"
  class_option :js, :type => :boolean, :default => true, :description => "Generate a template javascript file"
  class_option :coffee, :type => :boolean, :default => false, :description => "Generate a template coffeescript file"
  class_option :image, :type => :boolean, :default => true, :description => "Generate a blank image"
  class_option :spec, :type => :boolean, :default => true, :description => "Generate template spec files"
  class_option :view, :type => :boolean, :default => true, :description => "Generate a template view file"
  class_option :bare, :type => :boolean, :default => false, :description => "Generate a blank extension which only includes the ruby file"

  def initialize(*args)
    super
    if options[:template]
      self.class.source_root File.expand_path(options[:template], Rails.root)
    end
  end

  def create_chanko_file
    template 'chanko.rb', File.join("app", base_directory, file_name, "#{file_name}.rb")
  end

  def create_view_files
    if !options.bare? && options.view?
      ext = Rails.application.config.generators.options[:rails][:template_engine] || :erb
      template "chanko.#{ext}", File.join("app", base_directory, file_name, "views", "_show.html.#{ext}")
    end
  end

  def create_spec_file
    if !options.bare? && options.spec?
      template 'chanko_controller_spec.rb', File.join("app", base_directory, file_name, "spec/controllers", "#{file_name}_controller_spec.rb")
      template 'chanko_model_spec.rb', File.join("app", base_directory, file_name, "spec/models", "#{file_name}_model_spec.rb")
      template 'chanko_helper_spec.rb', File.join("app", base_directory, file_name, "spec/helpers", "#{file_name}_helper_spec.rb")
    end
  end

  def create_scss_files
    if !options.bare? && options.scss?
      template 'chanko.scss', File.join("app", base_directory, file_name, "stylesheets", "#{file_name}.scss")
      create_symlink('stylesheets')
    end
  end

  def create_js_files
    if !options.bare? && options.js? && !options.coffee?
      template 'chanko.js', File.join("app", base_directory, file_name, "javascripts", "#{file_name}.js")
      create_symlink('javascripts')
    end
  end

  def create_coffee_files
    if !options.bare? && options.coffee?
      template 'chanko.coffee', File.join("app", base_directory, file_name, "javascripts", "#{file_name}.js.coffee")
      create_symlink('javascripts', {:asset => true})
    end
  end

  def create_logo_file
    if !options.bare? && options.image?
      template 'chanko_blank.png', File.join("app", base_directory, file_name, "images", "logo.png")
      create_symlink('images')
    end
  end

  #this is for 'rails destroy chanko xxx' command
  def create_chanko_directory
    empty_directory File.join('app', base_directory, file_name), :verbose => false
  end

  private
  def create_symlink(path, option = {})
    if (defined? Sprockets) || option[:asset]
      FileUtils.mkdir_p("app/assets/#{path}/#{base_directory}/")
      destination = "app/assets/#{path}/#{base_directory}/#{file_name}"
      source = "../../../#{base_directory}/#{file_name}/#{path}"
      create_link destination, source, :symbolic => true
    else
      FileUtils.mkdir_p("public/#{path}/#{base_directory}/")
      destination = "public/#{path}/#{base_directory}/#{file_name}"
      source = "../../../app/#{base_directory}/#{file_name}/#{path}"
      create_link destination, source, :symbolic => true
    end
  end

  private
  def base_directory
    name = options[:directory] || Chanko.config.directory_name
    name.pluralize
  end

  def file_name
    name.underscore
  end
end
