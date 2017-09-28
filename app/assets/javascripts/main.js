var MAIN = {
	renderErrorState: function(data){
		var message = data.message
		var orderId = data.order.id
		var orderContainer = $("div.order__container[data-order-id-container=" + orderId + "]" )
		var feedbackContainer = $(orderContainer).find('.feedback__container');
		$(feedbackContainer).append( $('<span>').text(message).addClass('message error__message'));

	},
	renderSuccessState: function(data){
		var message = data.message
		var orderId = data.order.id
		var orderContainer = $("div.order__container[data-order-id-container=" + orderId + "]" )
		var feedbackContainer = $(orderContainer).find('.feedback__container');
		$(feedbackContainer).append( $('<span>').text("Success! - $" + data.refund.transactions[0].amount + " of order # " + data.order.order_number + " was refunded!").addClass('message success__message'));
	},
	findUploadedOrders: function(){
		var uploadedOrders = $('.uploaded--order__container');
		var lineItemObjs = [];
		if (uploadedOrders.length > 0){
			$.each(uploadedOrders, function(index, order) {
				var lineItems = $(order).find('.line-item__container');
				var firstElement = lineItems[0];
				var orderID = $(firstElement).data('upload-order-id');
				var orderNum = $(firstElement).data('upload-order-num');
				$.each(lineItems, function(index, lineItem) {
					var lineItemObj = {
						"order_num": $(lineItem).data('upload-order-num'),
						"order_id": $(lineItem).data('upload-order-id'),
						"item_num": $(lineItem).data('upload-line-item-sku'),
						"reason_code": $(lineItem).data('upload-line-item-reason-code'),
						"quantity": $(lineItem).data('upload-line-item-quantity'),
						"quality": $(lineItem).data('upload-line-item-quality'),
						"line_item_id": $(lineItem).data('upload-line-item-id')
					}
					lineItemObjs.push(lineItemObj);
				});
				MAIN.createOrderDomObject(orderID, orderNum, lineItemObjs);
				lineItemObjs = [];
			});
		}
	},
	createOrderDomObject: function(orderID, orderNum, lineItemObjs){
		$.ajax({
			url: '/create-order-dom-object',
			type: 'POST',
			data: {
				orderId: orderID,
				orderNum: orderNum,
				lineItems: JSON.stringify(lineItemObjs)
			},
		})
		.done(function(data) {
			if (data.status === "ok") {
				MAIN.updateDomWithOrdersForRefunds(data);
				console.log("success");
			} else {
				MAIN.updateDomWithErrorOrder(data);
			}
		})
		.fail(function() {
			console.log("error");
		})
		.always(function() {
			console.log("complete");
		});
	},
	updateDomWithErrorOrder: function(data){
		debugger;
	},
	updateDomWithOrdersForRefunds: function(data){
		if (Object.values(data.itemsToRefund).length >= 1){    
	        var orderContainer = $('<div>').addClass('order__container').attr('data-order-id-container',data.orderId).text(data.orderNum);
	        var feedbackContainer = $('<div>').addClass('feedback__container');
	        var refundButton = $('<button>').addClass('btn process--refund')
	        								.attr('data-order-id', data.orderId )
	        								.text('Process refund for Order #: ' + data.orderNum )
	        								.click(function(event) {
												var orderID = $(this).data('order-id');
												var lineItemRows = $(this).parent().find('.line-item__row');
												var lineItems = [];
												$(lineItemRows).each(function(index, el) {
													var lineItem = {
														reasonCode: $(el).data('reason-code'),
														quantity: $(el).data('quantity'),
														lineItemSku: $(el).data('line-item-sku')
													};
													lineItems.push(lineItem);
												});
												var pendingOrderContainer = $(this).parent();
												var pendingOrderTable = $(pendingOrderContainer).find('table');
												var pendingButton = $(pendingOrderContainer).find('button');
												var pendingFeedbackContainer = $(pendingOrderContainer).find('.feedback__container');
												$(pendingFeedbackContainer).addClass('pending');
												pendingOrderTable.addClass('faded')
												pendingButton.attr('disabled', 'disabled').addClass('faded');
												$.ajax({
													url: '/refund-order',
													type: 'POST',
													data: {
														orderId: orderID,
														lineItems: JSON.stringify(lineItems),
													},
												})
												.done(function(data) {
													console.log("success");
													console.log(data);
													if (data.status == "error"){
														MAIN.renderErrorState(data);
													} else if(data.status == "ok") {
														MAIN.renderSuccessState(data);
													} else if(data.status == "critical") {
														console.log(data);
													}
												})
												.fail(function(data) {
													console.log("error");
													console.log(data);
												})
												.always(function(data) {
													$('.feedback__container').removeClass('pending');
													console.log("complete");
												});
											});
	        var orderTable = $('<table>');
	        var orderTableBody = $('<tbody>');
	        $(orderTable).append(MAIN.orderTableHeaders);
	        $(orderContainer).append(orderTable)
	        				 .append(orderTableBody)
	        				 .append(feedbackContainer)
	        				 .append(refundButton);
	        $('.orders__container').append(orderContainer);
	        var orderLineItemsArray = Object.values(data.itemsToRefund);
		    $.each(orderLineItemsArray, function(index, orderLineItems) {
		        $.each(orderLineItems, function(index, lineItem) {
		        	var orderTableRow = '<tr class="line-item__row" data-reason-code="'+ lineItem.reason_code + '" data-quantity="'+ lineItem.quantity +'" data-line-item-sku="'+ lineItem.item_num +'">' +
										    '<td>\
										      <p>' +
										        lineItem.order_id +
										      '</p>\
										    </td>\
										    <td>' + 
										      '<a target="_blank" href="https://wearlively.com/admin/orders/'+ lineItem.order_id +'">' +
										        lineItem.order_num +
										      '</a>\
										    </td>\
										    <td>\
										      <p>' +
										        lineItem.name + 
										      '</p>\
										    </td>\
										    <td>\
										      <p>' +
										        lineItem.item_num + 
										      '</p>\
										    </td>' + 
										    '<td>\
										      <p>' +
										        '$' + lineItem.price + 
										      '</p>\
										    </td>\
										    <td>\
										      <p>' +
										        lineItem.quantity +
										      '</p>\
										    </td>\
										    <td>\
										      <p>' + 
										        lineItem.quality +
										      '</p>\
										    </td>\
										    <td>\
										      <p>' + 
										        lineItem.reason_code +
										      '</p>\
										    </td>\
										  </tr>';
					$(orderTable).append(orderTableRow);
		        });
		    });
		};
	    // Invalid Line Items
		if (Object.values(data.invalidLineItems).length >= 1){

		    var orderContainer = $('<div>').addClass('order__container invalid').attr('data-order-id-container',data.orderId).text(data.orderNum)
	        							   .attr('data-order-id', data.orderId )
	        							   .text('Invalid line item for order #: ' + data.orderNum );
	        var orderTable = $('<table>');
	        var orderTableBody = $('<tbody>');
	        $(orderTable).append(MAIN.orderTableHeaders);
	        $(orderContainer).append(orderTable)
	        				 .append(orderTableBody);
	        $('.orders__container').append(orderContainer);
	        var invalidLineItemsArray = Object.values(data.invalidLineItems);
		    $.each(invalidLineItemsArray, function(index, orderLineItems) {
		        $.each(orderLineItems, function(index, lineItem) {
		        	var orderTableRow = '<tr class="line-item__row" data-reason-code="'+ lineItem.reason_code + '" data-quantity="'+ lineItem.quantity +'" data-line-item-sku="'+ lineItem.item_num +'">' +
										    '<td>\
										      <p>' +
										        lineItem.order_id +
										      '</p>\
										    </td>\
										    <td>' + 
										      '<a target="_blank" href="https://wearlively.com/admin/orders/'+ lineItem.order_id +'">' +
										        lineItem.order_num +
										      '</a>\
										    </td>\
										    <td>\
										      <p>' +
										        lineItem.name + 
										      '</p>\
										    </td>\
										    <td class="flag">\
										      <p>' +
										        lineItem.item_num + 
										      '</p>\
										    </td>' + 
										    '<td>\
										      <p>' +
										        '$' + lineItem.price + 
										      '</p>\
										    </td>\
										    <td>\
										      <p>' +
										        lineItem.quantity +
										      '</p>\
										    </td>\
										    <td>\
										      <p>' + 
										        lineItem.quality +
										      '</p>\
										    </td>\
										    <td>\
										      <p>' + 
										        lineItem.reason_code +
										      '</p>\
										    </td>\
										  </tr>';
					$(orderTable).append(orderTableRow);
		        });
		    });
		};    
	},
	orderTableHeaders:  '<thead>\
		                    <tr>\
		                      <td>\
		                        <h4>\
		                          Shopify ID\
		                        </h4>\
		                      </td>\
		                      <td>\
		                        <h4>\
		                          Order Number\
		                        </h4>\
		                      </td>\
		                      <td>\
		                        <h4>\
		                          Variant Name\
		                        </h4>\
		                      </td>\
		                      <td>\
		                        <h4>\
		                          SKU\
		                        </h4>\
		                      </td>\
		                      <td>\
		                        <h4>\
		                          Price\
		                        </h4>\
		                      </td>\
		                      <td>\
		                        <h4>\
		                          Quantity\
		                        </h4>\
		                      </td>\
		                      <td>\
		                        <h4>\
		                          Quality\
		                        </h4>\
		                      </td>\
		                      <td>\
		                        <h4>\
		                          Reason for Return\
		                        </h4>\
		                      </td>\
		                    </tr>  \
		                  </thead>'
};

$( document ).on('turbolinks:load', function() {
	console.log("main.js loaded");
	MAIN.findUploadedOrders();
});


