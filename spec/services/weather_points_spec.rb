require "rails_helper"

RSpec.describe WeatherPoints do
  describe ".call" do
    let(:subject) { WeatherPoints.call(latitude, longitude) }
    let(:latitude) { 38.8987 }
    let(:longitude) { -77.0365 }

    before do
      # Stub out the cache methods to prevent caching
      allow(Rails.cache).to receive(:read).and_return(nil)
      allow(Rails.cache).to receive(:write).and_return(nil)
    end

    RSpec.shared_examples "successful weather points response" do
      it "returns a hash with points data" do
        VCR.use_cassette("weather_points") do
          result = subject
          expect(result).to be_a(Hash)
          expect(result[:forecast_url]).to eq("https://api.weather.gov/gridpoints/LWX/97,71/forecast")
        end
      end
    end

    RSpec.shared_examples "failed weather points response" do
      it "returns a hash with error" do
        result = subject
        expect(result).to be_a(Hash)
        expect(result[:error]).to be_eql("Failed to fetch weather grid data")
      end
    end

    context "with valid parameters" do
      it_behaves_like "successful weather points response"

      context "when cache lookup errors" do
        before do
          allow(Rails.cache).to receive(:read).and_raise(StandardError)
        end

        it_behaves_like "successful weather points response"
      end

      context "when Faraday returns 404" do
        before do
          allow(Faraday).to receive(:get).and_return(double(status: 404, body: ""))
        end

        it_behaves_like "failed weather points response"
      end
    end

    context "with invalid parameters" do
      let(:latitude) { nil }
      let(:longitude) { nil }

      it_behaves_like "failed weather points response"
    end
  end
end
