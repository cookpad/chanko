class Entry < ActiveRecord::Base
  attr_accessible :body, :deleted_at, :title
end
