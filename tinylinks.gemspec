# frozen_string_literal: true

require_relative "lib/tinylinks"

Gem::Specification.new do |spec|
  spec.name = "tinylinks"
  spec.version = Tinylinks::VERSION
  spec.authors = ["Jaime Rodas"]
  spec.summary = "CLI for TinyLinks"
  spec.description = "Command-line interface for the TinyLinks bookmarking API"
  spec.homepage = "https://github.com/jaimerodas/tinylinks-cli"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0"

  spec.files = Dir["lib/**/*.rb", "bin/*"]
  spec.bindir = "bin"
  spec.executables = ["tinylinks"]

  spec.add_dependency "thor", "~> 1.5"
end
