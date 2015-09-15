module EntryDeletion
  include Chanko::Unit

  scope(:view) do
    function(:delete_link) do
      render "/delete_link", :entry => entry if entry.persisted?
    end
  end

  scope(:controller) do
    function(:destroy) do
      entry = Entry.find(params[:id])
      entry.unit.soft_delete
      redirect_to entries_path
    end

    function(:index) do
      @entries = Entry.unit.active
    end
  end

  models do
    expand(:Entry) do
      scope :active, lambda { where(:deleted_at => nil) }

      def soft_delete
        update_attributes(:deleted_at => Time.now)
      end

      class_methods do
        def gc_all_soft_deleted_users
          where.not(deleted_at: nil).delete_all
        end
      end
    end
  end

  helpers do
    def link_to_deletion(entry)
      link_to "Delete", entry, :method => :delete
    end
  end
end
