# frozen_string_literal: true

require "spec_helper"
require "capybara"
require "capybara/dsl"
require "capybara/cuprite"
require "docbook/cli"

# Where the built test HTML will be placed
SPEC_DIR = File.expand_path("..", __dir__)
TEST_HTML_PATH = File.join(SPEC_DIR, "tmp/test_reader.html")
FIXTURE_XML = File.join(SPEC_DIR, "fixtures/kitchen-sink/kitchen-sink.xml")
FRONTEND_DIST = File.expand_path("../../frontend/dist", __dir__)

def frontend_built?
  File.exist?(File.join(FRONTEND_DIST, "app.css")) &&
    File.exist?(File.join(FRONTEND_DIST, "app.iife.js"))
end

if frontend_built?
  Capybara.register_driver :cuprite do |app|
    Capybara::Cuprite::Driver.new(app, headless: true, browser_options: { "no-sandbox": nil })
  end

  Capybara.default_driver = :cuprite
  Capybara.app_host = "file://"
  Capybara.default_max_wait_time = 10
end

RSpec.configure do |config|
  config.include Capybara::DSL, type: :feature

  config.before(:suite) do
    next unless frontend_built?

    FileUtils.mkdir_p(File.dirname(TEST_HTML_PATH))
    unless File.exist?(TEST_HTML_PATH) && File.mtime(TEST_HTML_PATH) > File.mtime(FIXTURE_XML)
      Docbook::CLI.start(["build", FIXTURE_XML, "-o", TEST_HTML_PATH])
    end
  end

  config.after(:each, type: :feature) do
    Capybara.reset_sessions!
  end
end
