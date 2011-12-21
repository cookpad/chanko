module Sample2Ext
  include Chanko::Unit

  scope(:view) do
    callback(:samename) do
      render(:partial => "/same_partial")
    end
  end

  async_view do
    def html
      render_partial("/same_partial")
    end
  end
end
