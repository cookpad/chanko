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
      render_to_string :partial => "/units/example_unit/test", :locals => { :local => "test" }
    end

    function(:nesting_locals_outer) do
      result = "#{outer_one}."
      result += invoke(:example_unit, :nesting_locals_inner, :locals => { :inner_one => "inner_one", :inner_two => "inner_two" }) do
        "#{outer_two}.#{run_default}"
      end
      result += ".#{outer_three}"
      result
    end

    function(:nesting_locals_inner) do
      "#{inner_one}.#{run_default}.#{inner_two}"
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

    function(:respond_to_helper?) do
      unit.respond_to?(:helper)
    end

    function(:render) do
      render "/units/example_unit/test", :local => "test"
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
