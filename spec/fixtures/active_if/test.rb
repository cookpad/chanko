Chanko::ActiveIf.define(:always_true) do |context, options|
  true
end

Chanko::ActiveIf.define(:always_false) do |context, options|
  false
end
