class AddQualityToLineItem < ActiveRecord::Migration[5.0]
  def change
  	add_column :line_items, :quality, :integer  	
  end
end
