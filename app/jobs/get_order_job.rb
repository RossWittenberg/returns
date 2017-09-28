class GetOrderJob < ApplicationJob
	queue_as :shopify
	
	rescue_from() do |e|
    	retry_job wait: 60.seconds
    end
	
	def perform(order_id)
		begin
			ShopifyAPI::Order.find(order_id)
		rescue ActiveResource::ResourceConflict, ActiveResource::ResourceNotFound, ActiveResource::ResourceInvalid 
			{
				message: "An error occured while importing your return file. Resource Conflict"
			}	
		end
	end
end