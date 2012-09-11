# coding: utf-8
module <%= class_name %>
  module Models
    expand("<%= class_name.camelize %>") do
<% for model in models -%>
      #belongs_to :<%= model %>
      #provide :<%= model %>
      #provide :<%= model %>=
<% end -%>

        class_methods do
<% for model in models -%>
          #def
          #  'hello'
          #end
          #provide :hello

          #def private_hello
          #  'hello'
          #end

<% end -%>
        end
    end
  end
end
