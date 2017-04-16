class CreateContentRatings < ActiveRecord::Migration
  def change
    create_table :content_ratings do |t|
      t.string :org
      t.string :tag
      t.string :short
      t.text :description

      t.timestamps
    end
  end
end
