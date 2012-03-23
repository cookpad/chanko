require 'spec_helper'

describe "Chanko", :type => :integration do
  before do
    ext_mock("AcceptanceTest")
    AcceptanceTest.class_eval do
      scope(:controller) do
        callback(:text) { render :text => 'hello'}
      end

      scope(:view) do
        callback(:render) do
          render :partial => '/show' 
        end

        callback(:outside) do
          'outside ' + run_default
        end

        callback(:blank) do
          
        end
      end
    end

    ext_mock("AcceptanceSkipTest")
    AcceptanceSkipTest.class_eval do
      active_if  { false }
      scope(:view) do
        callback(:skip) do
          'skip'
        end
      end
    end
  end

  it 'invoke with view' do
    visit "/invoke/with_view"
    (response || page).body.should match(/render view file/)
    (response || page).body.should match(/extension ext_acceptance_test ext_acceptance_test-render/)
  end

  it 'invoke by ext_action' do
    visit "/invoke/text"
    (response || page).body.should match(/hello/)
  end

  it 'nested invoke with blank result' do
    visit "/invoke/nested"
    (response || page).body.should == "<!DOCTYPE html>\n<html>\n<body>\nhello\noutside \n</body>\n</html>\n"
  end
end
