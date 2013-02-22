module ExampleUnit
  include Chanko::Unit

  shared(:shared) do |args|
    "shared #{args}"
  end

  scope(:controller) do
    function(:test) do
      "test"
    end

    function(:foo) do
      "foo"
    end

    function(:bar) do
      "bar"
    end

    function(:alias) do
      "alias"
    end

    function(:default) do
      run_default
    end

    function(:render) do
      render_to_string :partial => "/test", :locals => { :local => "test" }
    end
  end

  scope(:view) do
    function(:test) do
      "test"
    end

    function(:self) do
      self
    end

    function(:locals) do
      key
    end

    function(:falsy) do
      key.nil?
    end

    function(:shared) do
      shared("args")
    end

    function(:error) do
      raise_no_method_error
    end

    function(:helper) do
      unit.helper
    end

    function(:render) do
      render "/test", :local => "test"
    end

    function(:blank) do
      " "
    end
  end

  helpers do
    def helper
      "helper"
    end
  end
end
