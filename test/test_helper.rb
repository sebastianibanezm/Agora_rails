ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/reporters"

Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods
    self.use_instantiated_fixtures = false
    self.use_transactional_tests   = true
  end
end
