# frozen_string_literal: true

require_relative "lib/wipify/version"

Gem::Specification.new do |spec|
  spec.name        = "wipify"
  spec.version     = Wipify::VERSION
  spec.authors     = ["dedekm"]
  spec.email       = ["dedekmm@gmail.com"]
  spec.homepage    = "https://github.com/sinfin/wipify"
  spec.summary     = "Gem for adding e-commerce functionality."
  # spec.description = "TODO: Description of Wipify."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  #
  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.2.3"
  spec.add_dependency "aasm", "~> 5.2"
  spec.add_dependency "after_commit_everywhere", "~> 1.0"
  spec.add_dependency "pg", "~> 1.2"
  spec.add_dependency "ar-sequence"

  spec.add_development_dependency "pry-rails"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-rails_config"
  spec.add_development_dependency "rubocop-minitest"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "guard-rubocop"
  spec.add_development_dependency "guard-slimlint"
  spec.add_development_dependency "annotate"
  spec.add_development_dependency "slim"
end
