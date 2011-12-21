Hash.class_eval do
  def self.default_is_hash(number=1)
    if number > 0
      self.new { |h,v| h[v] = default_is_hash(number - 1 ) }
    else
      self.new
    end
  end
end
