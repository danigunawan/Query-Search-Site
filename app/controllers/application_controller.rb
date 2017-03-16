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
      if account = Account.find_by(id: current_account)
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

  def set_account
    @account = if current_account.present?
      Account.find_by(id: current_account)
    else
      nil
    end
  end

  def check_rate_limit
    if rate_limit_status = Twitter::REST::Request.new(@client, :get, 'https://api.twitter.com/1.1/application/rate_limit_status.json', resources: "application,search").perform
      if rate_limit_status[:resources][:application].values.first[:remaining] > 0
        puts "Remaining Application: #{rate_limit_status[:resources][:application].values.first[:remaining]}\n\nRemaining Search: #{rate_limit_status[:resources][:search].values.first[:remaining]}"

        any_remaining = rate_limit_status[:resources][:search].values.first[:remaining] > 0
        @account.update_attributes(searchable: any_remaining, restart: any_remaining ? nil : rate_limit_status[:resources][:search].values.first[:reset])
        any_remaining
      else
        @account.update_attributes(searchable: false, restart: rate_limit_status[:resources][:search].values.first[:reset])
        false
      end
    else
      @account.update_attributes(searchable: false, restart: rate_limit_status[:resources][:application].values.first[:reset])
      false
    end
  end
end
