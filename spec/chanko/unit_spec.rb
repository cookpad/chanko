require "spec_helper"

module Chanko
  describe Unit do
    before do
      unit.stub(:name => "ExampleUnit")
    end

    let(:unit) do
      Module.new { include Chanko::Unit }
    end

    let(:view) do
      Class.new { include Chanko::Helper }.new
    end

    describe "about active_if" do
      before do
        ActiveIf.define(:true) { true }
        ActiveIf.define(:false) { false }
      end

      after do
        ActiveIf.clear
      end

      subject { unit.active?(view) }

      describe ".active_if" do
        context "in default configuration" do
          it "is configured to return always true" do
            should be_true
          end
        end

        context "when labels are specified" do
          before do
            unit.active_if(:true, :false)
          end
          specify "all of defined conditions must pass" do
            should be_false
          end
        end

        context "when block is passed" do
          before do
            unit.active_if(:true) { false }
          end
          specify "all of defined conditions and block must pass" do
            should be_false
          end
        end
      end

      describe ".any" do
        context "when conditions returned true and false" do
          before do
            unit.instance_eval do
              active_if any(:true, :false)
            end
          end
          it { should be_true }
        end

        context "when all conditions returned false" do
          before do
            unit.instance_eval do
              active_if any(:false, :false)
            end
          end
          it { should be_false }
        end
      end

      describe ".none" do
        context "when all conditions returned false" do
          before do
            unit.instance_eval do
              active_if none(:false, :false)
            end
          end
          it { should be_true }
        end

        context "when conditions returned true and false" do
          before do
            unit.instance_eval do
              active_if none(:true, :false)
            end
          end
          it { should be_false }
        end
      end

      context "when using 'any' and 'none'" do
        context "'any' in 'none'" do
          before do
            unit.instance_eval do
              active_if none(any(:true, :false))
            end
          end
          it "returns negatived result of inner-expression" do
            should be_false
          end
        end

        context "'none' in 'any'" do
          before do
            unit.instance_eval do
              active_if any(none(:true), :false)
            end
          end
          it "uses none(:true) as false" do
            should be_false
          end
        end

        context "more nested" do
          before do
            unit.instance_eval do
              active_if any(any(none(:false), :false), :false)
            end
          end
          it { should be_true }
        end
      end
    end

    describe ".scope" do
      specify "given scope is recorded to used scope list" do
        unit.scope(:view) { }
        unit.scopes.keys.should == [ActionView::Base]
      end

      context "in the scoped block" do
        specify "current_scope returns given scope" do
          unit.scope(:view) do
            unit.current_scope.should == ActionView::Base
          end
        end
      end

      context "out of the scoped block" do
        specify "current_scope returns nil" do
          unit.scope(:view) { }
          unit.current_scope.should == nil
        end
      end
    end

    describe ".function" do
      it "stores given block with current_scope and given label" do
        unit.scope(:view) do
          unit.function(:test) do
            "test"
          end
        end
        unit.scopes[ActionView::Base][:test].block.call.should == "test"
      end
    end

    describe ".shared" do
      it "stores given block with given label" do
        unit.shared(:test) do
          "test"
        end
        unit.shared_methods[:test].call.should == "test"
      end
    end

    describe ".helpers" do
      it "provides interface for unit to define helper methods" do
        unit.helpers do
          def test
            "test"
          end
        end
        view.__example_unit_test.should == "test"
      end
    end

    describe ".models" do
      before do
        stub_const("ExampleModel", model_class)
        unit.models do
          expand(:ExampleModel) do
            scope :active, lambda { where(:deleted_at => nil) }

            has_one :user

            def test
              "test"
            end

            class_methods do
              def test
                "test"
              end
            end
          end
        end
      end

      let(:model_class) do
        Class.new do
          include UnitProxyProvider

          def self.scope(name, *args)
            singleton_class.class_eval do
              define_method(name) { "scoped" }
            end
          end

          def self.has_one(name, *args)
            singleton_class.class_eval do
              define_method(name) { args }
            end
          end
        end
      end

      it "defines instance methods with prefix" do
        ExampleModel.new.__example_unit_test.should == "test"
      end

      it "defines class methods with prefix" do
        ExampleModel.__example_unit_test.should == "test"
      end

      it "defines scope method with prefix" do
        ExampleModel.__example_unit_active.should == "scoped"
      end

      it "defines has_one association method with prefix" do
        ExampleModel.__example_unit_user.should == [:class_name => "User"]
      end
    end

    describe ".view_path" do
      it "returns path for its view directory" do
        unit.view_path.should == "#{Config.units_directory_path}/example_unit/views"
      end
    end
  end
end
