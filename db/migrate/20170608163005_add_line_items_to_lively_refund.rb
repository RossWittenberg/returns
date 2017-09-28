class AddLineItemsToLivelyRefund < ActiveRecord::Migration[5.0]
  def change
  	add_reference :line_items, :lively_refund, index: true
  end
end
