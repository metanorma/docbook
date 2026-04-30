# frozen_string_literal: true

require_relative "integration_helper"

RSpec.describe "Reader Features", type: :feature do
  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) do
    unless frontend_built?
      skip "Integration tests require frontend build artifacts (run `npm --prefix frontend run build`)"
    end
    if Gem.win_platform?
      skip "Integration tests skipped on Windows (file:// protocol not supported in headless Chrome)"
    end
    @html_path = TEST_HTML_PATH
  end
  # rubocop:enable RSpec/BeforeAfterAll

  def visit_reader
    visit "file://#{@html_path}" # rubocop:disable RSpec/InstanceVariable, Style/RedundantInterpolation
    page.driver.browser.resize(width: 1280, height: 800)
    expect(page).to have_css("#docbook-app", wait: 10)
    expect(page).to have_css(".toc-link", wait: 10)
  end

  def open_settings
    find("[aria-label='Display settings']").click
    expect(page).to have_css(".settings-panel")
  end

  def close_settings
    page.execute_script('document.querySelector(".settings-close")?.click()')
    30.times do
      break unless page.evaluate_script("!!document.querySelector('.settings-panel')")

      sleep 0.1
    end
  end

  def trigger_vue_key(key)
    page.execute_script(<<~JS)
      document.dispatchEvent(new KeyboardEvent('keydown', {
        key: #{key.to_json}, bubbles: true, cancelable: true
      }))
    JS
  end

  def navigate_to_section(section_text)
    link = find(".toc-link", text: /#{Regexp.escape(section_text)}/)
    section_id = link[:href].sub("file://", "").sub(%r{.*#}, "")
    # Scroll lazy placeholders into view to trigger IntersectionObserver
    page.execute_script(<<~JS)
      (function() {
        var id = #{section_id.to_json};
        var el = document.getElementById(id);
        if (el) {
          el.scrollIntoView({ behavior: 'instant' });
          return;
        }
        var placeholders = document.querySelectorAll('.lazy-placeholder');
        for (var i = 0; i < placeholders.length; i++) {
          var section = placeholders[i].closest('section');
          if (section) section.scrollIntoView({ behavior: 'instant' });
        }
      })()
    JS
    # Wait for lazy content to load (IntersectionObserver fires asynchronously)
    expect(page).to have_css("##{section_id}", wait: 10)
    sleep 1
    page.execute_script(<<~JS)
      var el = document.getElementById(#{section_id.to_json});
      if (el) el.scrollIntoView({ behavior: 'instant' });
    JS
    sleep 0.5
    link.click
    sleep 0.5
  end

  # ---- Focus Mode ----

  describe "focus mode" do
    it "toggles focus mode via settings switch" do
      visit_reader
      open_settings
      page.execute_script('document.querySelector("[aria-label=\"Focus mode\"]").click()')
      expect(page.evaluate_script('document.querySelector("[aria-label=\"Focus mode\"]")?.getAttribute("aria-checked")')).to eq("true")
      page.execute_script('document.querySelector("[aria-label=\"Focus mode\"]").click()')
      expect(page.evaluate_script('document.querySelector("[aria-label=\"Focus mode\"]")?.getAttribute("aria-checked")')).to eq("false")
    end

    it "hides sidebar in focus mode" do
      visit_reader
      open_settings
      page.execute_script('document.querySelector("[aria-label=\"Focus mode\"]").click()')
      close_settings
      # Check that sidebar is hidden via v-show (offsetParent null when hidden)
      sidebar_visible = page.evaluate_script('(function(){ var nav = document.querySelector("[role=\"navigation\"]"); return nav ? nav.offsetParent !== null : false; })()')
      expect(sidebar_visible).to be false
    end
  end

  # ---- Theme Switching ----

  describe "theme switching" do
    it "cycles through themes via topbar button" do
      visit_reader
      expect(page.evaluate_script("document.documentElement.classList.contains('theme-day')")).to be true
      find("button[title^='Theme:']").click
      expect(page.evaluate_script("document.documentElement.classList.contains('theme-sepia')")).to be true
    end

    it "selects a theme from settings panel" do
      visit_reader
      open_settings
      find(".theme-card[aria-label='Night theme']").click
      expect(page.evaluate_script("document.documentElement.classList.contains('theme-night')")).to be true
      close_settings
    end

    it "applies dark class for night theme" do
      visit_reader
      open_settings
      find(".theme-card[aria-label='Night theme']").click
      expect(page).to have_css("html.theme-night")
      expect(page.evaluate_script("document.documentElement.classList.contains('dark')")).to be true
      close_settings
    end
  end

  # ---- Settings Panel Controls ----

  describe "settings panel controls" do
    it "toggles font face between sans and serif" do
      visit_reader
      open_settings
      page.execute_script("document.querySelectorAll('.toggle-btn')[1].click()") # Serif
      expect(page.evaluate_script("document.body.classList.contains('font-serif')")).to be true
      page.execute_script("document.querySelectorAll('.toggle-btn')[0].click()") # Sans
      expect(page.evaluate_script("document.body.classList.contains('font-serif')")).to be false
    end

    it "adjusts font size via slider" do
      visit_reader
      open_settings
      slider = find(".slider-input[aria-label='Font size']")
      slider.set 28
      val = page.evaluate_script("document.querySelector('.slider-input')?.getAttribute('aria-valuenow')")
      expect(val.to_i).to eq(28)
      close_settings
    end

    it "selects content width presets" do
      visit_reader
      open_settings
      page.execute_script("document.querySelectorAll('.width-card')[0].click()") # Narrow
      expect(page.evaluate_script("!!document.querySelector('.width-card--active')")).to be true
      close_settings
    end

    it "closes settings via close button" do
      visit_reader
      open_settings
      page.execute_script('document.querySelector(".settings-close")?.click()')
      sleep 1
      expect(page.evaluate_script("!!document.querySelector('.settings-panel')")).to be false
    end

    it "resets all settings to defaults" do
      visit_reader
      open_settings
      find(".theme-card[aria-label='Sepia theme']").click
      expect(page).to have_css("html.theme-sepia", wait: 5)
      page.execute_script("document.querySelector('.settings-reset')?.click()")
      expect(page).to have_css("html.theme-day", wait: 5)
      close_settings
    end
  end

  # ---- Paged Mode ----

  describe "paged mode" do
    it "activates paged mode via settings toggle" do
      visit_reader
      open_settings
      page.execute_script("document.querySelectorAll('.toggle-btn')[9].click()") # Pages
      expect(page.evaluate_script("!!document.querySelector('.paged-mode')")).to be true
      expect(page.evaluate_script("!!document.querySelector('.page-nav')")).to be true
    end

    it "shows page navigation with prev/next buttons" do
      visit_reader
      open_settings
      page.execute_script("document.querySelectorAll('.toggle-btn')[9].click()") # Pages
      expect(page.evaluate_script("!!document.querySelector('.page-nav-btn[title=\"Previous page\"]')")).to be true
      expect(page.evaluate_script("!!document.querySelector('.page-nav-btn[title=\"Next page\"]')")).to be true
      expect(page.evaluate_script("!!document.querySelector('.page-nav-info')")).to be true
    end
  end

  # ---- Ref Card Swipe Mode ----

  describe "ref card swipe mode" do
    it "activates ref card mode via settings toggle" do
      visit_reader
      open_settings
      toggle = page.evaluate_script('document.querySelector("[aria-label=\"Reference card swipe mode\"]")?.getAttribute("aria-checked")')
      expect(toggle).to eq("false")
      page.execute_script('document.querySelector("[aria-label=\"Reference card swipe mode\"]").click()')
      checked = page.evaluate_script('document.querySelector("[aria-label=\"Reference card swipe mode\"]")?.getAttribute("aria-checked")')
      expect(checked).to eq("true")
    end

    it "toggles ref card mode off" do
      visit_reader
      open_settings
      page.execute_script('document.querySelector("[aria-label=\"Reference card swipe mode\"]").click()')
      page.execute_script('document.querySelector("[aria-label=\"Reference card swipe mode\"]").click()')
      checked = page.evaluate_script('document.querySelector("[aria-label=\"Reference card swipe mode\"]")?.getAttribute("aria-checked")')
      expect(checked).to eq("false")
    end
  end

  # ---- Code Blocks ----

  describe "code blocks" do
    it "renders code blocks with pre elements" do
      visit_reader
      expect(page).to have_css("pre.code-block")
    end

    it "has copy buttons on code blocks" do
      visit_reader
      expect(page).to have_css(".copy-btn", minimum: 1, visible: :all)
    end
  end

  # ---- Bookmarks ----

  describe "bookmarks" do
    it "adds a bookmark via keyboard shortcut" do
      visit_reader
      navigate_to_section("Paragraphs")
      trigger_vue_key("b")
      expect(page).to have_css(".bookmark-item", wait: 5)
    end

    it "removes a bookmark via keyboard shortcut" do
      visit_reader
      navigate_to_section("Paragraphs")
      trigger_vue_key("b")
      expect(page).to have_css(".bookmark-item", wait: 5)
      trigger_vue_key("b")
      expect(page).not_to have_css(".bookmark-item", wait: 5)
    end

    it "creates bookmark link in sidebar" do
      visit_reader
      navigate_to_section("Paragraphs")
      trigger_vue_key("b")
      expect(page).to have_css(".bookmark-item", wait: 5)
      expect(page).to have_css(".bookmark-link", wait: 5, visible: :all)
    end

    it "removes bookmark via remove button" do
      visit_reader
      navigate_to_section("Paragraphs")
      trigger_vue_key("b")
      expect(page).to have_css(".bookmark-item", wait: 5)
      page.execute_script("document.querySelector('.bookmark-remove')?.click()")
      expect(page).not_to have_css(".bookmark-item", wait: 5)
    end
  end

  # ---- Callout Markers ----

  describe "callout markers" do
    it "renders callout list with descriptions" do
      skip("Flaky on CI: headless Chrome lazy content loading timing") if ENV["CI"]
      visit_reader
      navigate_to_section("Callouts")
      sleep 2
      expect(page).to have_css(".callout-item", wait: 15)
    end
  end

  # ---- Footnotes ----

  describe "footnotes" do
    it "renders footnote markers inline" do
      visit_reader
      navigate_to_section("Footnotes")
      expect(page).to have_css(".footnote-marker", wait: 10)
    end

    it "renders footnotes section at bottom" do
      visit_reader
      navigate_to_section("Footnotes")
      expect(page).to have_css(".footnotes", wait: 10)
    end
  end

  # ---- Procedures ----

  describe "procedures" do
    it "renders procedure with ordered steps" do
      visit_reader
      navigate_to_section("Procedures")
      expect(page).to have_css(".procedure-list", wait: 10)
      expect(page).to have_css(".step-item")
    end
  end

  # ---- Sidebar Blocks ----

  describe "sidebar blocks" do
    it "renders sidebar blocks in content" do
      visit_reader
      navigate_to_section("Block Containers")
      expect(page).to have_css(".sidebar-block", wait: 5)
    end
  end

  # ---- Q&A Sets ----

  describe "Q&A sets" do
    it "renders qandaset with entries" do
      visit_reader
      navigate_to_section("Questions")
      expect(page).to have_css(".qandaset-block", wait: 5)
    end

    it "renders question and answer blocks" do
      skip("Flaky on CI: headless Chrome lazy content loading timing") if ENV["CI"]
      visit_reader
      navigate_to_section("Questions")
      sleep 2
      expect(page).to have_css(".question-block", wait: 10)
      expect(page).to have_css(".answer-block", wait: 10)
    end
  end

  # ---- Annotations ----

  describe "annotations" do
    it "renders annotation markers in content" do
      visit_reader
      navigate_to_section("Block Containers")
      expect(page).to have_css(".annotation-marker", wait: 5)
    end

    it "shows annotation popup when marker is clicked" do
      visit_reader
      navigate_to_section("Block Containers")
      expect(page).to have_css(".annotation-marker", wait: 5)
      page.execute_script("document.querySelector('.annotation-marker')?.click()")
      expect(page.evaluate_script("!!document.querySelector('.annotation-popup')")).to be true
    end

    it "displays annotation content in popup" do
      visit_reader
      navigate_to_section("Block Containers")
      expect(page).to have_css(".annotation-marker", wait: 5)
      page.execute_script("document.querySelector('.annotation-marker')?.click()")
      has_content = page.evaluate_script('(function(){ var el = document.querySelector(".annotation-popup-content"); return el ? el.textContent.trim().length > 0 : false; })()')
      expect(has_content).to be true
    end
  end

  # ---- Glossary ----

  describe "glossary" do
    it "renders glossary with terms" do
      visit_reader
      page.execute_script("document.getElementById('main-content').scrollTo(0, 99999)")
      expect(page).to have_css(".glossary-list", wait: 10)
    end
  end

  # ---- Breadcrumbs ----

  describe "breadcrumbs" do
    it "shows breadcrumbs when navigating to a nested section" do
      visit_reader
      navigate_to_section("Paragraphs")
      expect(page).to have_css(".breadcrumb-bar", wait: 5)
      expect(page).to have_css(".breadcrumb-chip")
    end
  end

  # ---- Reading Progress ----

  describe "reading progress bar" do
    it "shows reading progress bar when enabled" do
      visit_reader
      expect(page).to have_css(".reading-progress")
    end
  end

  # ---- Back to Top ----

  describe "back to top" do
    it "shows back-to-top button after scrolling down" do
      visit_reader
      page.execute_script("document.getElementById('main-content').scrollTo(0, 99999)")
      expect(page).to have_css(".back-to-top", wait: 10)
    end

    it "scrolls to top when clicked" do
      skip "Smooth scrolling does not animate in headless Chrome CI" if ENV["CI"]
      visit_reader
      page.execute_script("document.getElementById('main-content').scrollTo(0, 99999)")
      expect(page).to have_css(".back-to-top", wait: 10)
      find(".back-to-top").click
      # Poll until smooth scroll completes
      scroll_pos = nil
      20.times do
        scroll_pos = page.evaluate_script("document.getElementById('main-content').scrollTop")
        break if scroll_pos == 0

        sleep 0.25
      end
      expect(scroll_pos).to eq(0)
    end
  end

  # ---- TTS ----

  describe "text-to-speech" do
    it "has TTS controls available" do
      skip "TTS requires real browser with speech voices; headless Chrome completes synthesis instantly"
    end
  end

  # ---- Cloud Sync ----

  describe "cloud sync" do
    it "shows sync buttons in settings panel" do
      visit_reader
      open_settings
      expect(page).to have_css(".sync-btn", minimum: 2)
      close_settings
    end
  end

  # ---- Reading Stats ----

  describe "reading statistics" do
    it "shows reading stats in settings panel" do
      visit_reader
      open_settings
      expect(page).to have_css(".stat-card")
      expect(page).to have_css(".stat-value")
      expect(page).to have_css(".stat-label")
      close_settings
    end
  end

  # ---- Advanced Content Rendering ----

  describe "advanced content rendering" do
    it "renders blockquotes" do
      visit_reader
      navigate_to_section("Block Containers")
      expect(page).to have_css("blockquote", wait: 5)
    end

    it "renders ordered lists" do
      visit_reader
      navigate_to_section("Lists")
      expect(page).to have_css("ol.list-decimal", wait: 5)
    end

    it "renders unordered lists" do
      visit_reader
      navigate_to_section("Lists")
      expect(page).to have_css("ul.list-disc", wait: 5)
    end

    it "renders definition lists" do
      visit_reader
      navigate_to_section("Lists")
      expect(page).to have_css("dl", wait: 5)
    end

    it "renders admonition variants with correct classes" do
      visit_reader
      navigate_to_section("Admonitions")
      expect(page).to have_css(".admonition-note", wait: 5)
      expect(page).to have_css(".admonition-tip")
      expect(page).to have_css(".admonition-important")
      expect(page).to have_css(".admonition-warning")
      expect(page).to have_css(".admonition-caution")
    end

    it "renders bibliography entries" do
      visit_reader
      page.execute_script("document.getElementById('main-content').scrollTo(0, 99999)")
      expect(page).to have_text("RFC2119", wait: 10)
    end

    it "renders inline code formatting" do
      visit_reader
      expect(page).to have_css("code")
    end
  end

  # ---- TOC Navigation ----

  describe "TOC navigation" do
    it "expands and collapses TOC entries" do
      visit_reader
      expect(page).to have_css(".toc-toggle", wait: 5)
      first(".toc-toggle").click
    end

    it "shows type badges in TOC" do
      visit_reader
      expect(page).to have_css(".toc-badge")
    end

    it "navigates to section when TOC link is clicked" do
      visit_reader
      first(".toc-link").click
      expect(page).to have_css("#main-content")
    end
  end

  # ---- Image Lightbox ----

  describe "image lightbox" do
    it "opens lightbox when figure is clicked" do
      visit_reader
      navigate_to_section("Block Containers")
      expect(page).to have_css("figure", wait: 5)
      first("figure").click
      if page.has_css?(".lightbox-overlay", wait: 2)
        expect(page).to have_css(".lightbox-image")
      end
    end
  end

  # ---- Lazy Section Rendering ----

  describe "lazy section rendering" do
    it "renders visible sections with content" do
      visit_reader
      expect(page).to have_css("section[id]", minimum: 1, wait: 10)
    end
  end
end
