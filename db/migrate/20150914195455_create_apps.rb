class CreateApps < ActiveRecord::Migration
  def change
    create_table :apps do |t|
      t.string :name
      t.string :uuid
      t.string :publisher
      t.string :url

      t.timestamps null: false
    end
  end
end
