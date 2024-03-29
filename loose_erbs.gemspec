# frozen_string_literal: true

require_relative "lib/loose_erbs/version"

Gem::Specification.new do |spec|
  spec.name = "loose_erbs"
  spec.version = LooseErbs::VERSION
  spec.authors = ["Hartley McGuire"]
  spec.email = ["skipkayhil@gmail.com"]

  spec.summary = "A tool to help find Loose ERBs in your app!"
  # spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/skipkayhil/loose_erbs"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # TODO: bump to first released version that uses Prism
  spec.add_dependency "actionview", ">= 7.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
