ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module AdminAuthHelper
  def sign_in_admin
    post admin_login_path, params: { token: ENV.fetch("ADMIN_TOKEN", "admin-secret") }
  end
end

class ActionDispatch::IntegrationTest
  include AdminAuthHelper
end
