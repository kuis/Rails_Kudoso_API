class CreateFamilyActivities < ActiveRecord::Migration
  def change
    create_table :family_activities do |t|
      t.integer :family_id
      t.integer :activity_template_id
      t.string :name
      t.string :description
      t.integer :cost, default: 0
      t.integer :reward, default: 0
      t.integer :time_block
      t.boolean :restricted, default: false
      t.text :device_chains

      t.timestamps
    end

    add_index :family_activities, :family_id
    add_index :family_activities, :activity_template_id
  end
end
