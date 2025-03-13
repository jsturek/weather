# README

# Overview*
This Ruby on Rails weather application allows a user to retrieve a weekly forecast for inputted address. It requires user to provide street address, city, state and zipcode. It is limited to United States address due to the source of forecast information only supports the United States.

# Data Sources
This application uses the API web service provided by the [National Weather Service](https://www.weather.gov/documentation/services-web-api). This API was chosen since it is free to all (with rate limits) and current does not require an API Key for authentication.  See the [FAQ](https://weather-gov.github.io/api/general-faqs) for more details on the API.

The API requires two api calls to get the forecast data. The first call to `https://api.weather.gov/points/{lat},{lon}` to get grid points data related to the requested latitude and longitude.  These grid points allows the service to group locations with shared forecast information.  This response will provide another API endpoint to use to get the actual forecast data.  An example is `https://api.weather.gov/gridpoints/LWX/96,70/forecast`.

Because the initial API call requires latitude and longitude, the address data collected by this application needs to be geocoded.  The National Weather Service
does not provide geocoding services so the application uses [US Census Bureau Geocoding Service](https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.html) for the geocoding.  This service was chosen since to was free and does not require authentication.

# API Response Caching
The application will use redis to cache API responses to reduce the number of calls needed since this data is fairly static. Currently all caches are stored 
for 30 minutes.

For geocoding this application requires street address, city, state and zipcode to request geocoding from US Census Bureau Geocoding Service API.  The application
will cache results by `zipcode` to group requests with same zipcodes to use the cached latitude and longitude which will be sufficient for weather geocoding.

The other API calls to National Weather Service will also be cached.
* The grid points call is cached by `latitude` and `longitude`
* The forecast call is cached by the entire URL

# Developer Info
This application was created using the `rails-new` tool with support for [dev container](https://guides.rubyonrails.org/getting_started_with_devcontainer.html) for a full-features development environment in [Visual Studio Code](https://code.visualstudio.com/).

Some useful commands to run in dev container terminal in Visual Studio Code.
* `bin/rails server` to start rails server and access application at `localhost:3000/`
* `bin/rubocop` to run rubocop ruby linter
* `bin/rails spec` to run rspec test suite. After running coverage report written to `coverage/index.html`
