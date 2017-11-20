class AddInstantToListings < ActiveRecord::Migration[5.1]
  def change
    add_column :listings, :instant, :integer, default: 1
  end
end
