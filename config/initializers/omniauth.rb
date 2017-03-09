Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, Credentials::APP_KEY, Credentials::APP_SECRET
end
