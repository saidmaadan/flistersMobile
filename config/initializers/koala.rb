Koala.configure do |config|
  config.app_id = ENV.fetch('FB_API_KEY')
  config.app_secret = ENV.fetch('FB_API_SECRET')
end
