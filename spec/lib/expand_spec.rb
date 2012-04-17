require 'spec_helper'

describe Chanko do
  before(:all) do
    Prefix = Module.new.tap {|expander| expander.send(:include, Chanko::Expand) }
  end

  shared_examples_for 'expand' do
    describe 'basic' do
      let(:expander) do
        Module.new.tap do |expander|
          expander.send(:include, Chanko::Expand)
          expander.prefix = '__prefix__'
        end
      end

      it 'should attach' do
        klass = Class.new
        expander.should_not be_expanded
        expander.attach(klass)
        expander.should be_expanded
      end

      it 'should define expanded method' do
        klass = Class.new
        expander.module_eval do
          def hello; 'hello'; end
        end
        expander.attach(klass)
        klass.new.should be_respond_to('__prefix__hello')
      end

      it 'should define expanded class method' do
        klass = Class.new
        expander.module_eval do
          class_methods do
            def hello; 'hello'; end
          end
        end
        expander.prefix = '__prefix__'
        expander.attach(klass)
        klass.should be_respond_to('__prefix__hello')
      end

      it 'should run after callback' do
        klass = Class.new
        mock = mock("Dummy")
        mock.should_receive(:hello)
        expander.send(:add_after_callback) do
          mock.hello
        end
        expander.attach(klass)
      end
    end

    describe 'model' do
      [:expander, :expander2].each do |expander_name|
        let(expander_name) do
          Module.new.tap do |expander|
            expander.send(:include, Chanko::ActiveRecord::Expand)
            expander.prefix = '__prefix__'
          end
        end
      end

        let(:user_klass) { Class.new(User) { set_table_name 'users'; def self.name; "User"; end; def self.to_s; "User"; end } }
        let(:recipe_klass) { Class.new(Recipe) { set_table_name 'recipes'; def self.name; "Recipe"; end; def self.to_s; "Recipe"; end } }

      after do
        Object.const_remove('TestUser') rescue nil
        Object.const_remove('TestRecipe') rescue nil
      end

      it 'should use has_one association' do
        expander.class_eval { has_one :recipe, :foreign_key => 'user_id' }
        expander.attach(user_klass)
        user = user_klass.create!(:name => 'alice')
        user.ext(:prefix).recipe.should be_blank
        user.create___prefix__recipe(:title => 'hello')
        Recipe.count(:conditions => {:user_id => user.id}).should == 1
      end

      it 'should use has_many association' do
        expander.class_eval { has_many :recipes, :foreign_key => 'user_id' }
        expander.attach(user_klass)
        user = user_klass.create!(:name => 'alice')
        user.ext(:prefix).recipes.should be_blank
        user.ext(:prefix).recipes.create!(:title => 'hello')
        user.ext(:prefix).recipes.should have(1).records
      end

      it 'should use belongs_to association' do
        expander.class_eval { belongs_to :user }
        expander.attach(recipe_klass)
        user = user_klass.create!(:name => 'alice')
        recipe = recipe_klass.create!(:user_id => user.id, :title => 'hello')
        recipe.ext(:prefix).user.id.should == user.id
      end

      it 'should use scope' do
        expander.class_eval do
          scope :named, lambda { |name| where(:name => name) }
          scope :alice, lambda { where(:name => 'alice') }
        end
        expander.attach(user_klass)
        %w(alice bob).each { |name| User.create!(:name => name) }

        user_klass.should have(2).records
        user_klass.ext(:prefix).named('alice').should have(1).records
        user_klass.ext(:prefix).alice.should have(1).records
      end

      it 'should work with a block' do
        expander.class_eval do
          has_many :recipes do
            def hello
              'hello'
            end
          end
        end
        expander.attach(user_klass)
        user_klass.new.__prefix__recipes.hello.should == 'hello'
      end

      it 'should use scope with association proxy' do
        AssociationProxyTestRecipe = recipe_klass
        expander.class_eval do
          has_many :recipes, :class_name => "::AssociationProxyTestRecipe"
        end
        expander.attach(user_klass)
        alice = user_klass.create!(:name => 'alice')
        bob = user_klass.create!(:name => 'bob')
        alice_icecream = AssociationProxyTestRecipe.create!(:title => 'icecream', :user_id => alice.id)
        AssociationProxyTestRecipe.create!(:title => 'chocolate', :user_id => alice.id)
        AssociationProxyTestRecipe.create!(:title => 'pancake', :user_id => bob.id)
        AssociationProxyTestRecipe.create!(:title => 'icecream', :user_id => bob.id)

        expander2.class_eval do
          scope :icecream, lambda { where(:title => 'icecream') }
        end
        expander2.attach(AssociationProxyTestRecipe)
        user_klass.where(:id => alice.id).first.ext(:prefix).recipes.ext(:prefix).icecream.size.should == 1
        user_klass.where(:id => alice.id).first.ext(:prefix).recipes.ext(:prefix).icecream.first.id.should == alice_icecream.id
      end
    end
  end

  context 'with cache_classes' do
    before { Chanko.config.cache_classes = true }
    it_should_behave_like 'expand'
  end

  context 'without cache_classes' do
    before { Chanko.config.cache_classes = false }
    it_should_behave_like 'expand'
  end
end
