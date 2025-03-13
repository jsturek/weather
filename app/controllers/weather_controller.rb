require_relative "../services/geocode"
require_relative "../services/forecast"
require_relative "../services/weather_points"

class WeatherController < ApplicationController
  def index
    @forecast_from_cache = forecast[:from_cache] || false
    @forecast_summary = forecast[:days] || []
    puts "Forecast Summary: #{@forecast_summary.inspect}"
    @valid_params = valid_params?
  end

  def empty_forecast
    {
      from_cache: false,
      days: []
    }
  end

  def forecast
    return empty_forecast unless weather_points[:forecast_url].present?
    @forecast ||= Forecast.call(weather_points[:forecast_url])
  end

  def geocode
    return {} unless valid_params?
    @geocode ||= Geocode.call(params[:street], params[:city], params[:state], params[:zip])
  end

  def weather_points
    return {} unless geocode[:latitude].present? && geocode[:longitude].present?
    @weather_points ||= WeatherPoints.call(geocode[:latitude], geocode[:longitude])
  end

  def valid_params?
    @valid_params ||= params[:street].present? && params[:city].present? && params[:state].present? && params[:zip].present?
  end
end
