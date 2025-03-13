class Forecast
  attr_reader :url

  CACHE_DURATION = 30.minutes

  # This class fetches the weather forecast for a given url
  def self.call(url)
    new(url).call
  end

  def call
    return forecast_error unless url.present?
    return cache_lookup if cache_lookup.present?

    response = forecast_response
    Rails.cache.write(cache_key, response, expires_in: CACHE_DURATION) if response.first.present?
    response
  end

  private

  def initialize(url)
    @url = url
  end

  def cache_lookup
    # lookup key from cache and flag it as from_cache
    @cache_lookup ||= Rails.cache.read(cache_key).merge(from_cache: true)
  rescue
    # Ignore cache read errors
    # TODO: Log the error
    nil
  end

  def forecast_error
    { error: "Failed to fetch forecast data" }
  end

  def format_forecast_periods(periods)
    periods.map do |period|
      {
        name: period["name"],
        date: DateTime.parse(period["startTime"]).to_date.to_s,
        start_time: period["startTime"],
        end_time: period["endTime"],
        is_daytime: period["isDaytime"],
        temperature: period["temperature"],
        temperature_unit: period["temperatureUnit"],
        wind_speed: period["windSpeed"],
        wind_direction: period["windDirection"],
        short_forecast: period["shortForecast"],
        detailed_forecast: period["detailedForecast"]
      }
    end
  end

  def group_forecast_by_date(forecast)
    forecast_by_date = {}
    forecast.each do |item|
      forecast_by_date[item[:date]] ||= []
      forecast_by_date[item[:date]] << item
    end
    forecast_by_date
  end

  def forecast_response
    return forecast_error unless url.present?

    response = Faraday.get(url)
    if response.status == 200
      data = JSON.parse(response.body)
      periods = data.dig("properties", "periods") || []
      return forecast_error unless periods.present?

      formatted_periods = format_forecast_periods(periods)
      {
        from_cache: false,
        days:  group_forecast_by_date(formatted_periods)
      }
    else
      forecast_error
    end
  end

  def cache_key
    @cache_key ||= "forecast-#{url}"
  end
end
