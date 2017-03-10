class HomeController < ApplicationController
  before_action :set_account
  before_action :set_client, only: [:search]

  def index
    @accounts = Account.all
  end

  def search
    if @client.present?
      if params[:search].present?
        curr_time = Date.parse(params[:to]).strftime("%Y-%m-%d")
        prev_time = Date.parse(params[:from]).strftime("%Y-%m-%d")
        @user_query = "#{params[:search]} since:#{prev_time}"

        begin
          results = if curr_time != prev_time
            @client.search(@user_query, until: curr_time, result_type: 'recent', lang: 'ja')
          else
            @client.search(@user_query, result_type: 'recent', lang: 'ja')
          end
        rescue Twitter::Error::TooManyRequests
          results = nil
          @error = "Twitter Error: Too Many Requests"
        end

        if results.present? && results.is_a?(Twitter::SearchResults)
          @total_results = results.count
          @graph_data = params[:show_zero].present? ? get_graph_data(results, prev_time, curr_time) : get_graph_data(results)
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

  def get_graph_data(tweets, prev_time=nil, curr_time=nil)
    hours_hash = {}
    time_grouped = tweets.group_by{ |tweet| tweet.created_at.strftime('%Y-%m-%d %H') }
    time_grouped.each do |key, values|
      time_grouped_hour = Time.parse(key).in_time_zone('Asia/Manila').strftime('%Y-%m-%d %H:%M')
      hours_hash[time_grouped_hour] = values.count
    end

    unless prev_time == nil && curr_time == nil
      prev_time = prev_time.to_datetime.in_time_zone('Asia/Manila').beginning_of_day.to_i
      curr_time = curr_time.to_datetime.in_time_zone('Asia/Manila').end_of_day.to_i
      (prev_time..curr_time).step(1.hour) do |hour_record|
        check_key = Time.at(hour_record).utc.strftime('%Y-%m-%d %H:%M')
        hours_hash[check_key] = 0 unless hours_hash.keys.include?(check_key)
      end
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
