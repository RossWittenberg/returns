class HomeController < ShopifyApp::AuthenticatedController  

  def index
    @orders = ShopifyAPI::Order.find(:all, params: { limit: 100 })
    @products = ShopifyAPI::Product.find(:all, params: { limit: 100 })
  end

  def import_complete

  end

  def import_orders
  	@file = params[:file]
  	if @file
  		@uploaded_items_to_refund = import_orders_for_refund(@file)
  	else
  		flash.now[:error] = "Please select a file to upload."
  	end	
  end

  def refund_order
  	items_to_refund = []
	order_id = params[:orderId].to_i
	@order = GetOrderJob.perform_now(order_id)
	sleep 2.0
  	refund_line_items = JSON.parse(params[:lineItems])
  	refund_line_items.each do |line_item|
		line_item_object = @order.line_items.select { |i| i.sku == line_item["lineItemSku"].to_s }.first
		items_to_refund << {
			line_item_id: line_item_object.id,
    		quantity: line_item["quantity"]
		} if line_item
	end
	formatted_refund = {
	    :shipping => {
			:full_refund => false
	    },
	    :refund_line_items => items_to_refund
    }
	if @order && formatted_refund && (!@order.is_a? String)
		@calculated_refund = calculate_refund(formatted_refund, @order)
		unless @calculated_refund.is_a? Hash
			@refund = create_refund_object(@order, @calculated_refund)
			if @refund && !@calculated_refund.attributes["refund_line_items"].empty?
				render :json => { 
					:status => :ok, 
					:order	=> @order,
					:refund => @refund
				}
			elsif @refund && @calculated_refund.attributes["refund_line_items"].empty?
				render :json => { 
					:status => :error, 
					:message => "An error occured while refunding order ##{@order.order_number}. One or more of the SKUs are likely incorrect.",
					:order	=> @order
				}		
			else
				render :json => { 
					:status => :ok, 
					:message => "Failure!!", 
					:html => "...insert html..." 
				}
			end
		else
			render :json => { 
				:status => :error, 
				:message => @calculated_refund[:message],
				:order	=> @calculated_refund[:order]
			}
		end
  	else
  		render :json => { 
			:status => :critcal, 
			:message => "An error occured while importing your return file. Resource Not Found"
		}
  	end
  end 

  def create_order_dom_object
  	items_to_refund_array = []
  	invalid_line_items_array = []
	order_id = params[:orderId].to_i
	order_num = params[:orderNum].to_i
  	refund_line_items = JSON.parse(params[:lineItems])
	@order = GetOrderJob.perform_now(order_id) 
	sleep 1	
	if	@order && (!@order.is_a? Hash)
	  	refund_line_items.each do |line_item|
			line_item_object = @order.line_items.select { |i| i.sku == line_item["item_num"].to_s }.first || "invalid"
			if line_item_object === "invalid"
				line_item["name"] = "Invalid Shopify SKU"
				line_item["price"] = "N/A"
				invalid_line_items_array << line_item
			else
				line_item["name"] = line_item_object.name
				line_item["price"] = line_item_object.price
				items_to_refund_array << line_item
			end	
		end
	else 
		refund_line_items.each do |line_item|
			line_item["name"] = "Invalid Shopify SKU"
			line_item["price"] = "N/A"
			invalid_line_items_array << line_item
		end
	end	
	items_to_refund = items_to_refund_array.empty? ? false : items_to_refund_array.group_by { |i| i["order_num"] }
	invalid_line_items = invalid_line_items_array.empty? ? false : invalid_line_items_array.group_by { |i| i["order_num"] }
	if items_to_refund && !items_to_refund.empty?
		render :json => { 
			:status => :ok,
			:orderId => order_id,
			:orderNum => order_num,
			:itemsToRefund => items_to_refund,
			:invalidLineItems => invalid_line_items
		}
	elsif invalid_line_items && !invalid_line_items.empty?
		render :json => { 
			:status => :ok,
			:orderId => order_id,
			:orderNum => order_num,
			:itemsToRefund => [],
			:invalidLineItems => invalid_line_items
		}
	else	
		render :json => { 
			:status => :error, 
			:message => "Failure!! There was a problem with one of your orders."
		}
	end
  end

  private

	def calculate_refund(data, order)
		puts "CALCULATING..."
		begin
			ShopifyAPI::Refund.calculate(data, :params => {:order_id => order.id})
		rescue ActiveResource::ResourceConflict
			"An error occured while importing your return file. Resource Conflict"
		rescue ActiveResource::ResourceInvalid 
			{
				message: "An error occured while importing ORDER ##{order.order_number}. This type of error is generally caused when attempting to refund an item that has already been refunded.",
				order: order
			}	
		end
	end

	def create_refund_object(order, calculated_refund)
		calculated_refund.transactions.each {|t| t.kind = "refund"}
		refund = ShopifyAPI::Refund.create(
	      :order_id => order.id,
	      :note => "Refund administered via LIVELY Returns App",
	      :restock => false,
	      :shipping => { :full_refund => false },
	      :refund_line_items => calculated_refund.refund_line_items,
	      :transactions => calculated_refund.transactions,
	      :notify => true
	    )
	end

	def import_orders_for_refund(file)
		if file
			csv_file_path = file.tempfile if file

			valid_items = []
			flagged_items = []

			all_items_submitted_for_refund = {
				valid_skus: [],
				invalid_skus: []
			}
			
			items_to_refund = []
			
			CSV.foreach(csv_file_path, :headers => true) do |row|
				order_num = row.to_hash["Ext Order #"][3..-1].to_i
				order_id = row.to_hash["Shopify Order ID"]
				sku = row.to_hash["Item #"]
				reason_code = row.to_hash["Reason Code"]
				quantity = row.to_hash["QTY RTND"].to_i
				quality = row.to_hash["Quality"].to_i
				item_to_refund = {
					order_num: order_num,
					order_id: order_id,
					reason_code: reason_code,
					sku: sku,
					quantity: quantity,
					quality: quantity
				}
				valid_items << item_to_refund
			end	
	
			all_items_submitted_for_refund[:valid_skus] << valid_items.group_by { |i| i[:order_num] } unless valid_items.blank?
			all_items_submitted_for_refund[:invalid_skus] << flagged_items unless flagged_items.empty?
			return all_items_submitted_for_refund
		else
			return false

		end	
	end
end