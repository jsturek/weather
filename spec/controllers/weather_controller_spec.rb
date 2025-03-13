require "rails_helper"

RSpec.describe WeatherController, type: :controller do
  describe "GET #index" do
    let(:subject) { get :index, params: }
    let(:params) { {} }
    let(:geocode_response) { { latitude: 40.0, longitude: -95.0 } }
    let(:weather_points_response) { { grid_id: "123", grid_x: 1, grid_y: 2, forecast_url: "http://example.com" } }
    let(:forecast_response) do
      {
        from_cache: false,
        periods: [
          {
            name: "Today",
            temperature: "75",
            temperature_unit: "F",
            wind_speed: "5 mph",
            wind_direction: "ESE",
            short_forecast: "Sunny",
            detailed_forecast: "Sunny, with a high near 75. East southeast wind around 5 mph."
          }
        ]
      }
    end

    before do
      allow(Geocode).to receive(:call).and_return(geocode_response)
      allow(WeatherPoints).to receive(:call).and_return(weather_points_response)
      allow(Forecast).to receive(:call).and_return(forecast_response)
    end

    context "without params" do
      let(:params) { {} }
      it "returns http success" do
        subject
        expect(response).to have_http_status(:success)
      end
    end

    context "with params" do
      let(:params) do
        {
          street: "4610 Christopher Court",
          city: "Lincoln",
          state: "NE",
          zip: "68516"
        }
      end

      it "returns http success" do
        subject
        expect(response).to have_http_status(:success)
      end
    end
  end
end
