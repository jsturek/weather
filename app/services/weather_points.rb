class WeatherPoints
  attr_reader :latitude, :longitude

  CACHE_DURATION = 30.minutes

  # This class fetches the weather points data for a given latitude and longitude
  def self.call(latitude, longitude)
    new(latitude, longitude).call
  end

  def call
    return cache_lookup if cache_lookup.present?

    response = points_response
    Rails.cache.write(cache_key, response, expires_in: CACHE_DURATION) if response[:grid_id].present?
    response
  end

  private

  def initialize(latitude, longitude)
    @latitude = latitude
    @longitude = longitude
  end

  def cache_lookup
    @cache_lookup ||= Rails.cache.read(cache_key)
  rescue
    # Ignore cache read errors
    # TODO: Log the error
    nil
  end

  def format_points_data(data)
    {
      grid_id: data["gridId"],
      grid_x: data["gridX"],
      grid_y: data["gridY"],
      forecast_url: data["forecast"]
    }
  end

  def cache_key
    @cache_key ||= "weather-points-#{longitude}-#{latitude}"
  end

  def points_error
    { error: "Failed to fetch weather grid data" }
  end

  def points_response
    # no need to make a request if latitude or longitude is not present
    return points_error unless latitude.present? && longitude.present?

    response = Faraday.get(points_url)
    if response.status == 200
      points_data = JSON.parse(response.body)
      properties = points_data.dig("properties") || {}
      return points_error unless properties.present?

      format_points_data(properties)
    else
      points_error
    end
  end

  def points_url
    @points_url ||= "https://api.weather.gov/points/#{latitude},#{longitude}"
  end
end
