module Chanko
  module Aliases
    mattr_accessor :aliases
    self.aliases = {
      :view => "ActionView::Base",
      :controller => "ActionController::Base",
      :model => "ActiveRecord::Base",
    }

    def self.alias(name)
      return name unless self.aliases.keys.include?(name)
      self.aliases[name]
    end
  end
end
