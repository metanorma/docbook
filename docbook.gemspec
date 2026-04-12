# frozen_string_literal: true

require_relative "lib/docbook/version"

Gem::Specification.new do |spec|
  spec.name = "docbook"
  spec.version = Docbook::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Ruby model-accessor for DocBook XML from OASIS"
  spec.description = "A Ruby library for parsing, accessing, and serializing DocBook 5 XML documents using lutaml-model"
  spec.homepage = "https://github.com/metanorma/docbook"
  spec.required_ruby_version = ">= 3.2.0"
  spec.license = "BSD-2-Clause"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/metanorma/docbook"
  spec.metadata["changelog_uri"] = "https://github.com/metanorma/docbook/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  # Include frontend dist assets (built locally, not committed to git)
  Dir.glob("frontend/dist/*").each { |f| spec.files << f }
  Dir.glob("frontend/src/**/*").each { |f| spec.files << f }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "lutaml-model", "~> 0.8.0"
  spec.add_dependency "nokogiri"
  spec.add_dependency "thor"
  spec.add_dependency "liquid", "~> 5.0"
  spec.add_dependency "marcel"
end
