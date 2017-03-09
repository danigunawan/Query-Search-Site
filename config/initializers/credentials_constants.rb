module Credentials
  CONFIG = YAML.load_file("#{::Rails.root}/config/twitter_credentials.yml")[::Rails.env]
  APP_KEY = CONFIG['api_key']
  APP_SECRET = CONFIG['api_secret']
  GOOGLE_KEY = CONFIG['google_search_key']
  GOOGLE_API_KEY = CONFIG['google_api_key']
end
