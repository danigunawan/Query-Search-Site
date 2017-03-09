class HomeController < ApplicationController
  before_action :set_account
  before_action :set_client, only: [:search]

  def index
    @accounts = Account.all
  end

  def search
    if @client.present?
      if params[:search].present?
        curr_time = Time.now
        prev_time = Time.now - 24.hours
        begin
          results = @client.search(params[:search], since: prev_time.strftime("%Y-%m-%d"), until: curr_time.strftime("%Y-%m-%d"), result_type: 'recent', lang: 'ja')
        rescue Twitter::Error::TooManyRequests
          results = nil
          @error = "Twitter Error: Too Many Requests"
        end
        if results.present?
          @total_results = results.count
          @graph_data = get_graph_data(results)
        end
        @partial_results = Kaminari.paginate_array(results.to_a).page(params[:page]).per(20)
        @google_results, @google_page = get_google_results(params[:search])
      else
        @error = "No Search Query"
      end
    else
      @error = "No Account Selected"
    end
  end

  def page_google_results
    @google_results, @google_page = get_google_results(params[:search], params[:start])
  end

  private

  def get_google_results(query, start=1)
    uri = URI('https://www.googleapis.com/customsearch/v1')
    params = { :q => query, :cx => Credentials::GOOGLE_KEY, :key => Credentials::GOOGLE_API_KEY, start: start.to_i }
    uri.query = URI.encode_www_form(params)

    res = Net::HTTP.get_response(uri)
    return JSON.parse(res.body), start
  end

  def get_graph_data(tweets)
    hours_hash = {}
    time_grouped = tweets.group_by{ |tweet| tweet.created_at.strftime('%Y-%m-%d %H') }
    time_grouped.each do |key, values|
      time_grouped_hour = Time.parse(key).strftime('%H:%M')
      hours_hash[time_grouped_hour] = values.count
    end
    hours_hash
  end

  def set_account
    @account = if current_account.present?
      Account.find(current_account)
    else
      nil
    end
  end
end
