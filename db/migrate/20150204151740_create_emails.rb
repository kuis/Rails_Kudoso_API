class CreateEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.integer :contact_id
      t.string :address
      t.boolean :is_primary, default: false

      t.timestamps
    end

    add_index :emails, :contact_id
  end
end
