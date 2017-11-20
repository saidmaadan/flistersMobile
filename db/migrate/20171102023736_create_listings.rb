class CreateListings < ActiveRecord::Migration[5.1]
  def change
    create_table :listings do |t|
      t.string :listing_type
      t.string :apartment_type
      t.integer :accommodate
      t.integer :bedroom
      t.integer :bathroom
      t.string :listing_name
      t.text :summary
      t.string :address
      t.boolean :tv
      t.boolean :kitchen
      t.boolean :air
      t.boolean :heating
      t.boolean :internet
      t.integer :price
      t.boolean :active
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
