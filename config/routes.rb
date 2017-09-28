Rails.application.routes.draw do
  root :to => 'home#index'
  mount ShopifyApp::Engine, at: '/'
  match 'process-refunds', to: 'home#process_refunds', via: [:post]
  match 'import-orders', to: 'home#import_orders', via: [:get]
  match 'import-orders', to: 'home#import_orders', via: [:post]
  match 'import-complete', to: 'home#import_complete', via: [:get]
  match 'refund-order', to: 'home#refund_order', via: [:post]  
  match 'calculate-and-process-refund', to: 'home#calculate_and_process_refund', via: [:post]
  match 'create-order-dom-object', to: 'home#create_order_dom_object', via: [:post]
end
