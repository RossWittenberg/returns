class AddQuantityToLineItems < ActiveRecord::Migration[5.0]
  def change
  	add_column :line_items, :quantity, :integer
  	add_column :line_items, :sub_total, :float
  	add_column :line_items, :total_tax, :float
  end
end
