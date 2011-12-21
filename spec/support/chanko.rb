Chanko::ActiveIf.expanded_judgements << lambda do |context, options|
   Chanko::Test::Mock.enabled?(context, options[:ext], options)
end


RSpec.configure do |c|
  c.include Chanko::Test::Mock
  c.include Chanko::Test::Macro

  c.before do
    Chanko.config.raise = true
  end

  c.after do
    Chanko::Test::Mock.reset!
  end
end

