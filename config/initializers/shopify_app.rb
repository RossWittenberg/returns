ShopifyApp.configure do |config|
  config.application_name = "LIVELY Returns"
  config.api_key = ENV['RETURNS_APP_API_KEY']
  config.secret = ENV['RETURNS_APP_SECRET']
  config.scope = "read_orders, write_orders, read_products, write_products"
  config.embedded_app = false
  # config.redirect_uri = Rails.env.production? ? "https://returns-app.herokuapp.com/auth/shopify/callback" : "http://localhost:3000/auth/shopify/callback"
end