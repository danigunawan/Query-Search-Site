class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def current_account
    @account ||= session['account_id']
  end

  def destroy_account
    @account = nil
    session['account_id'] = nil
  end

  def set_client
    if @client.present?
      @client
    else
      if account = Account.where(id: current_account).first
        @client = Twitter::REST::Client.new do |config|
          config.consumer_key        = Credentials::APP_KEY
          config.consumer_secret     = Credentials::APP_SECRET
          config.access_token        = account.token
          config.access_token_secret = account.token_secret
        end
      else
        nil
      end
    end
  end
end
