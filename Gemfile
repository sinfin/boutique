# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in boutique.gemspec.
gemspec

gem "sprockets-rails"

gem "folio", "~> 3.0", github: "sinfin/folio", branch: "v3"
# gem "folio", path: "../folio"

gem "dragonfly_libvips", github: "sinfin/dragonfly_libvips", branch: "more_geometry"

gem "cells"
gem "cells-slim", "0.0.6"
gem "cells-rails", github: "sinfin/cells-rails"

gem "sidekiq", "~> 6.5"
gem "sidekiq-cron", "~> 1.8"

gem "omniauth"
gem "omniauth-facebook"
gem "omniauth-google-oauth2"
gem "omniauth-twitter2"
gem "omniauth-rails_csrf_protection"

group :test do
  gem "minitest", "~> 5.14.4"
  gem "mocha", "~> 1.14.0"
  gem "minitest-stub_any_instance"
  gem "factory_bot"
  gem "capybara", "~> 2.13"
end

group :development do
  gem "puma", "< 6"

  gem "faker", require: false
end

group :development, :test do
  gem "pry-byebug"
end
