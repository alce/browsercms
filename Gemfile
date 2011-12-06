source 'http://rubygems.org'

# Load this project as a gem.
gemspec

gem 'jquery-rails'
gem 'rack', '1.3.3' # At least until 1.3.5 is out. Avoids warnings about already defined constants.
gem "mysql2"
gem 'paperclip', '~> 2.3.5'

gem 'yard', :groups=>[:development, :test]
gem 'bluecloth', :groups=>[:development, :test] # For YARD

group :test do
  gem 'factory_girl_rails', '1.0.1'
  gem 'test-unit', '2.1.1'
  # :require=>false allows mocha to correctly modify the test:unit code to add mock() and stub()
  gem "mocha", '=0.9.8', :require=>false
  gem "sqlite3-ruby", :require => "sqlite3"

  # Cucumber and dependencies
  gem 'capybara'
  gem 'database_cleaner'
  gem 'cucumber-rails'
  gem 'cucumber'
  gem 'launchy'
  gem 'ruby-prof'
end
