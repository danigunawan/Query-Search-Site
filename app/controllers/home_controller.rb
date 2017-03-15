class HomeController < ApplicationController
  before_action :set_client
  before_action :set_account

  def index
    @accounts = Account.all
    check_rate_limit if @client.present?
  end

  def search
    if @client.present?
      if check_rate_limit
        if params[:search].present?
          curr_time = Date.parse(params[:to]).strftime("%Y-%m-%d")
          prev_time = Date.parse(params[:from]).strftime("%Y-%m-%d")

          conditions = set_conditions(params)
          begin
            results, results_metadata = request_search(conditions)
            @next_page = results_metadata[:next_results].scan(/max_id=\d+/).first.scan(/\d+/).first

            if results.present?
              @total_results = results.count
              @graph_data = get_graph_data(results, prev_time, curr_time)
            end
            @partial_results = results
          rescue Twitter::Error::TooManyRequests
            @error = "Twitter Error: Too Many Requests"
          end
          #@google_results, @google_page = get_google_results(params[:search])
        else
          @error = "No Search Query"
        end
      else
        @error = "User Cannot Request Anymore. Wait 15 minutes"
      end
    else
      @error = "No Account Selected"
    end
  end

  def page_google_results
    @google_results, @google_page = get_google_results(params[:search], params[:start])
  end

  private

  def set_conditions(params)
    curr_time = Date.parse(params[:to]).strftime("%Y-%m-%d")
    prev_time = Date.parse(params[:from]).strftime("%Y-%m-%d")
    @user_query = "#{params[:search]} since:#{prev_time}"

    conditions = {}
    conditions[:result_type] = 'recent'
    conditions[:lang] = 'ja'
    conditions[:count] = 100
    conditions[:since_id] = params[:since_id] if params[:since_id].present?
    conditions[:max_id] = params[:max_id] if params[:max_id].present?
    conditions[:until] = curr_time if curr_time != prev_time
    conditions[:q] = @user_query
    conditions
  end

  def request_search(conditions)
    search_returns = Twitter::REST::Request.new(@client, :get, 'https://api.twitter.com/1.1/search/tweets.json', conditions).perform
    return search_returns[:statuses], search_returns[:search_metadata]
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

  def get_google_results(query, start=1)
    uri = URI('https://www.googleapis.com/customsearch/v1')
    params = { :q => query, :cx => Credentials::GOOGLE_KEY, :key => Credentials::GOOGLE_API_KEY, start: start.to_i }
    uri.query = URI.encode_www_form(params)

    res = Net::HTTP.get_response(uri)
    return JSON.parse(res.body), start
  end

  def get_graph_data(tweets, prev_time=nil, curr_time=nil)
    hours_hash = {}
    begin
      time_grouped = tweets.group_by{ |tweet| Time.parse(tweet[:created_at]).strftime('%Y-%m-%d %H') }
      time_grouped.each do |key, values|
        time_grouped_hour = Time.parse(key).in_time_zone('Asia/Manila').strftime('%Y-%m-%d %H:%M')
        hours_hash[time_grouped_hour] = values.count
      end

      prev_time = prev_time.to_datetime.in_time_zone('Asia/Manila').beginning_of_day.to_i
      curr_time = curr_time.to_datetime.in_time_zone('Asia/Manila').end_of_day.to_i
      (prev_time..curr_time).step(1.hour) do |hour_record|
        check_key = Time.at(hour_record).utc.strftime('%Y-%m-%d %H:%M')
        hours_hash[check_key] = 0 unless hours_hash.keys.include?(check_key)
      end
    rescue Twitter::Error::TooManyRequests
    end
    hours_hash
  end

  def set_account
    @account = if current_account.present?
      Account.find_by(id: current_account)
    else
      nil
    end
  end
end
