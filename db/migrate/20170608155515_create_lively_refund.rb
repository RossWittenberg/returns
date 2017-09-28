class CreateLivelyRefund < ActiveRecord::Migration[5.0]
  def change
    create_table :lively_refunds do |t|
    	t.string :order_id
    	t.timestamps
    end
  end
end
