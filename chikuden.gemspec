# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chikuden/version"

Gem::Specification.new do |spec|
  spec.name          = "chikuden"
  spec.version       = Chikuden::VERSION
  spec.authors       = ["EBIHARA, Yuichiro"]
  spec.email         = ["yuichiro.ebihara@scalar-labs.com"]

  spec.summary       = "Cursor-based pagination cache using Redis Sorted Set"
  spec.description   = "Chikuden caches paginated record IDs using Redis Sorted Set to eliminate repeated LIMIT/OFFSET queries. Works with Kaminari and Pagy."
  spec.homepage      = "https://github.com/yebihara/chikuden"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "redis", ">= 4.0"
  spec.add_dependency "railties", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"

  spec.add_development_dependency "bundler", ">= 2.0"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
