class CreateEntries < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.string :title
      t.string :body
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
