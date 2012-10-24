class CreateCosts < ActiveRecord::Migration
  def change
    create_table :costs do |t|
      t.integer :chargeable_id
      t.integer :chargeable_type
      t.datetime :valid_from
      t.datetime :valid_to
      t.decimal :price, :precision=>8, :scale=>3

      t.timestamps
    end
  end
end
