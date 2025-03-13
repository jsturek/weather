require "rails_helper"

RSpec.describe Geocode do
  describe ".call" do
    let(:subject) { Geocode.call(street, city, state, zip) }
    let(:street) { "1600 Pennsylvania Ave NW" }
    let(:city) { "Washington" }
    let(:state) { "DC" }
    let(:zip) { "20500" }

    before do
      # Stub out the cache methods to prevent caching
      allow(Rails.cache).to receive(:read).and_return(nil)
      allow(Rails.cache).to receive(:write).and_return(nil)
    end

    RSpec.shared_examples "successful geocode response" do
      it "returns a hash with latitude and longitude" do
        VCR.use_cassette("geocode") do
          result = subject
          expect(result).to be_a(Hash)
          expect(result[:latitude]).to eq(38.8987)
          expect(result[:longitude]).to eq(-77.0365)
        end
      end
    end

    RSpec.shared_examples "failed geocode response" do
      it "returns a hash with error" do
        result = subject
        expect(result).to be_a(Hash)
        expect(result[:error]).to be_eql("Failed to fetch geocode data")
      end
    end

    context "with valid parameters" do
      context "without cache lookup" do
        it_behaves_like "successful geocode response"
      end

      context "when cache lookup errors" do
        before do
          allow(Rails.cache).to receive(:read).and_raise(StandardError)
        end

        it_behaves_like "successful geocode response"
      end

      context "when Faraday returns 404" do
        before do
          allow(Faraday).to receive(:get).and_return(double(status: 404, body: ""))
        end

        it_behaves_like "failed geocode response"
      end
    end

    context "without street parameter" do
      let(:street) { "" }

      it_behaves_like "failed geocode response"
    end
  end
end
