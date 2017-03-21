Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, Credentials::APP_KEY, Credentials::APP_SECRET
end
OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
