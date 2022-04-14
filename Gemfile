# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in wipify.gemspec.
gemspec

gem "sprockets-rails"

gem "folio", github: "sinfin/folio", branch: "petr/dragonfly-libvips-multi-site-rails-7"
# gem "folio", path: "../folio"

group :test do
  gem "minitest", "~> 5.14.4"
  gem "factory_bot"
end

group :development do
  gem "puma", "< 6"

  gem "faker", require: false
end
