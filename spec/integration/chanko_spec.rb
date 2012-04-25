require 'spec_helper'

describe "Chanko", :type => :integration do
  before do
    mock_unit("AcceptanceTest")
    AcceptanceTest.class_eval do
      scope(:controller) do
        function(:text) { render :text => 'hello'}
      end

      scope(:view) do
        function(:render) do
          render :partial => '/show' 
        end

        function(:outside) do
          'outside ' + run_default
        end

        function(:blank) do
          
        end

        function(:content_for) do
          content_for :content_for_hello do
            'content_for_hello'
          end
        end
      end
    end

    mock_unit("AcceptanceSkipTest")
    AcceptanceSkipTest.class_eval do
      active_if  { false }
      scope(:view) do
        function(:skip) do
          'skip'
        end
      end
    end
  end

  it 'invoke with view' do
    visit "/invoke/with_view"
    (response || page).body.should match(/render view file/)
    (response || page).body.should match(/unit unit__acceptance_test unit__acceptance_test__render/)
  end

  it 'invoke by unit_action' do
    visit "/invoke/text"
    (response || page).body.should match(/hello/)
  end

  it 'nested invoke with blank result' do
    visit "/invoke/nested"
    (response || page).body.should == "<!DOCTYPE html>\n<html>\n<body>\nhello\noutside \n</body>\n</html>\n"
  end

  it 'nested invoke with content_for' do
    no_raise_chanko_exception
    visit "/invoke/content_for_hello"
    (response || page).body.should == "<!DOCTYPE html>\n<html>\n<body>\n\nbefore\nbefore\ncontent_for_hellodefault\nafter\n\nafter\n\n</body>\n</html>\n"
  end
end
