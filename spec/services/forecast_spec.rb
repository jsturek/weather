require "rails_helper"

RSpec.describe Forecast do
  describe ".call" do
    subject { Forecast.call(url) }

    before do
      # Stub out the cache methods to prevent caching
      allow(Rails.cache).to receive(:read).and_return(nil)
      allow(Rails.cache).to receive(:write).and_return(nil)
    end

    RSpec.shared_examples "successful forecast response" do
      it "returns forecast data" do
        VCR.use_cassette("forecast") do
          result = subject
          expect(result).to be_a(Hash)
          expect(result[:from_cache]).to be(false)
          expect(result[:days]).to be_a(Hash)
          expect(result[:days].count).to eq(7)
          expect(result[:days].first).to be_a(Array)
          expect(result[:days].first.count).to eq(2)
        end
      end
    end

    RSpec.shared_examples "failed forecast response" do
      it "returns a hash with error" do
        result = subject
        expect(result).to be_a(Hash)
        expect(result[:error]).to be_eql("Failed to fetch forecast data")
      end
    end

    context "with valid parameters" do
      let(:url) { "https://api.weather.gov/gridpoints/OKX/33,34/forecast" }

      it_behaves_like "successful forecast response"

      context "when cache lookup errors" do
        before do
          allow(Rails.cache).to receive(:read).and_raise(StandardError)
        end

        it_behaves_like "successful forecast response"
      end

      context "when Faraday returns 404" do
        before do
          allow(Faraday).to receive(:get).and_return(double(status: 404, body: ""))
        end

        it_behaves_like "failed forecast response"
      end
    end

    context "with invalid parameters" do
      let(:url) { "" }

      it_behaves_like "failed forecast response"
    end
  end
end
