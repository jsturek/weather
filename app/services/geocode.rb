class Geocode
  attr_reader :street, :city, :state, :zip

  CACHE_DURATION = 30.minutes

  def self.call(street, city, state, zip)
    new(street, city, state, zip).call
  end

  def call
    return cache_lookup if cache_lookup.present?

    response = geocode_response
    Rails.cache.write(cache_key, response, expires_in: CACHE_DURATION) if response[:latitude].present?
    response
  end

  private

  def initialize(street, city, state, zip)
    @street = street
    @city = city
    @state = state
    @zip = zip
  end

  def cache_key
    # use zip to create a unique cache key to treat each zip as a unique location
    @cache_key ||= "geocode-#{zip}"
  end

  def cache_lookup
    @cache_lookup ||= Rails.cache.read(cache_key)
  rescue
    # Ignore cache read errors
    # TODO: Log the error
    nil
  end

  def geocode_error
    { error: "Failed to fetch geocode data" }
  end

  def geocode_response
    # no need to make a request if street is not present
    return geocode_error unless street.present?

    response = Faraday.get(geocode_url)
    if response.status == 200
      data = JSON.parse(response.body)
      matches = data.dig("result", "addressMatches") || []
      address = matches.first || {}
      {
        latitude: address.dig("coordinates", "y").round(4),
        longitude: address.dig("coordinates", "x").round(4)
      }
    else
      geocode_error
    end
  end

  def geocode_url
    @geocode_url ||= "https://geocoding.geo.census.gov/geocoder/locations/address?street=#{street}&city=#{city}&state=#{state}&zip=#{zip}&benchmark=Public_AR_Current&format=json"
  end
end
