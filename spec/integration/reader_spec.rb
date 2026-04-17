# frozen_string_literal: true

require_relative "integration_helper"

RSpec.describe "DocBook Reader", type: :feature do
  before(:all) do
    unless frontend_built?
      skip "Integration tests require frontend build artifacts (run `npm --prefix frontend run build`)"
    end
    @html_path = TEST_HTML_PATH
  end

  def visit_reader
    visit "file://#{@html_path}"
  end

  # ---- Content Rendering ----

  describe "content rendering" do
    it "renders the title page" do
      visit_reader
      expect(page).to have_css(".title-page")
    end

    it "renders code blocks" do
      visit_reader
      expect(page).to have_css("pre")
    end

    it "renders paragraphs" do
      visit_reader
      expect(page).to have_css("p")
    end

    it "renders admonitions" do
      visit_reader
      expect(page).to have_css(".admonition")
    end

    it "renders the main content area" do
      visit_reader
      expect(page).to have_css("#main-content")
    end

    it "renders the Vue app mount point" do
      visit_reader
      expect(page).to have_css("#docbook-app")
    end
  end

  # ---- Navigation ----

  describe "sidebar and TOC navigation" do
    it "has a sidebar with table of contents" do
      visit_reader
      expect(page).to have_css("[role='navigation']")
    end

    it "toggles sidebar visibility" do
      visit_reader
      find("[aria-label='Toggle table of contents']").click
      find("[aria-label='Toggle table of contents']").click
    end

    it "shows TOC links" do
      visit_reader
      expect(page).to have_css(".toc-link")
    end
  end

  # ---- Theme & Settings ----

  describe "settings panel" do
    it "opens settings panel" do
      visit_reader
      find("[aria-label='Display settings']").click
      expect(page).to have_css("[role='dialog'][aria-label='Display settings']")
    end

    it "has theme options in settings" do
      visit_reader
      find("[aria-label='Display settings']").click
      expect(page).to have_css("[role='dialog'][aria-label='Display settings']")
      expect(page).to have_css(".theme-card")
    end

    it "has font size controls" do
      visit_reader
      find("[aria-label='Display settings']").click
      expect(page).to have_css("input[type='range']")
    end
  end

  # ---- Search ----

  describe "search" do
    it "opens search modal with keyboard shortcut" do
      visit_reader
      find("body").send_keys("/")
      expect(page).to have_css("[role='dialog'][aria-label='Search']")
    end

    it "can type and find search results" do
      visit_reader
      find("body").send_keys("/")
      within("[role='dialog'][aria-label='Search']") do
        find(".search-input").set("paragraph")
      end
      expect(page).to have_css(".search-result", wait: 5)
    end

    it "closes search modal with Escape" do
      visit_reader
      find("body").send_keys("/")
      expect(page).to have_css("[role='dialog'][aria-label='Search']")
      find("body").send_keys(:escape)
      expect(page).not_to have_css("[role='dialog'][aria-label='Search']")
    end
  end

  # ---- Keyboard Shortcuts ----

  describe "keyboard shortcuts" do
    it "opens keyboard help with ?" do
      visit_reader
      find("body").send_keys("?")
      expect(page).to have_css("[role='dialog'][aria-label='Keyboard shortcuts']")
    end

    it "closes keyboard help with close button" do
      visit_reader
      find("body").send_keys("?")
      expect(page).to have_css("[role='dialog'][aria-label='Keyboard shortcuts']")
      # The close button triggers Vue reactivity
      within("[role='dialog'][aria-label='Keyboard shortcuts']") do
        find(".help-close").click
      end
      # Vue Transition may keep the element briefly — check it disappears
      sleep 0.5
      expect(page).not_to have_css("[role='dialog'][aria-label='Keyboard shortcuts']", wait: 5)
    end
  end

  # ---- Accessibility ----

  describe "accessibility" do
    it "has skip to content link" do
      visit_reader
      expect(page).to have_css(".skip-link")
    end

    it "has ARIA landmarks" do
      visit_reader
      expect(page).to have_css("[role='main']")
      expect(page).to have_css("[role='navigation']")
      expect(page).to have_css("[role='banner']")
    end

    it "has screen reader announcements" do
      visit_reader
      expect(page).to have_css("[aria-live='polite']")
    end
  end
end
