class CreateLineItem < ActiveRecord::Migration[5.0]
  def change
    create_table :line_items do |t|
    	t.string :variant_id
    	t.string :product_id
    	t.text   :return_reason
    	t.timestamps
    end
  end
end
