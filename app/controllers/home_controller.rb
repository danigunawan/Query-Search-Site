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
          curr_time = Date.parse(params[:until]).strftime("%Y-%m-%d")
          prev_time = Date.parse(params[:since]).strftime("%Y-%m-%d")

          conditions = set_conditions(params)
          begin
            results = request_search(conditions)

            if results.present?
              @next_page = results.last[:id]
              results.shift(1) if params[:max_id].present?
              @total_results = results.count + params[:prev_count].to_i
              @graph_data = get_graph_data(results, prev_time, curr_time)

              if params[:graph_data].present?
                #prev_data = @account.graph_data
                prev_data = session[:graph_data]
                @graph_data.merge!(prev_data){ |key, graph_data_val, prev_data_val| graph_data_val + prev_data_val.to_i }
              else
                session[:graph_data] = nil
                #@account.update_attributes(graph_data: nil)
              end
              session[:graph_data] = @graph_data.select {|key, value| value != 0 }
              #@account.update_attributes(graph_data: @graph_data.select {|key, value| value != 0 })
            end
            @partial_results = results
          rescue Twitter::Error::TooManyRequests
            @error = "Twitter Error: Too Many Requests"
          end
          @google_results, @google_page = get_google_results(params[:search])
        else
          @error = "No Search Query"
        end
      else
        @google_results, @google_page = get_google_results(params[:search]) if params[:search].present?
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
    curr_time = Date.parse(params[:until]).strftime("%Y-%m-%d")
    prev_time = Date.parse(params[:since]).strftime("%Y-%m-%d")
    @user_query = "#{params[:search]} since:#{prev_time}"

    conditions = {}
    conditions[:result_type] = 'recent'
    conditions[:lang] = 'ja'
    conditions[:count] = 100
    conditions[:since_id] = params[:since_id] if params[:since_id].present?
    conditions[:max_id] = params[:max_id] if params[:max_id].present?
    conditions[:until] = curr_time
    conditions[:q] = @user_query
    conditions
  end

  def request_search(conditions)
    search_returns = Twitter::REST::Request.new(@client, :get, 'https://api.twitter.com/1.1/search/tweets.json', conditions).perform
    search_returns[:statuses]
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
        time_grouped_hour = Time.zone.parse(key).strftime('%Y-%m-%d %H:%M %z')
        hours_hash[time_grouped_hour] = values.count
      end

      prev_time = prev_time.to_datetime.beginning_of_day.to_i
      curr_time = (curr_time.to_datetime - 1.day).end_of_day.to_i
      (prev_time..curr_time).step(1.hour) do |hour_record|
        check_key = Time.at(hour_record).utc.strftime('%Y-%m-%d %H:%M %z')
        hours_hash[check_key] = 0 unless hours_hash.keys.include?(check_key)
      end
    rescue Twitter::Error::TooManyRequests
    end
    hours_hash
  end
end
