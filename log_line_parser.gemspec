# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'log_line_parser/version'

Gem::Specification.new do |spec|
  spec.name          = "log_line_parser"
  spec.version       = LogLineParser::VERSION
  spec.required_ruby_version = ">= 2.0.0"
  spec.authors       = ["HASHIMOTO, Naoki"]
  spec.email         = ["hashimoto.naoki@gmail.com"]

  spec.summary       = %q{A simple parser of Apache access log}
  spec.description   = %q{A simple parser of Apache access log: it parses a line of Apache access log and turns it into an array of strings or a Hash object. And from the command line, you can use it as a conversion tool of file format (to CSV/TSV) or as a filtering tool of access records.}
  spec.homepage      = "https://github.com/nico-hn/LogLineParser"
  spec.license       = "MIT"

  #  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  #  # delete this section to allow pushing this gem to any host.
  #  if spec.respond_to?(:metadata)
  #    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  #  else
  #    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  #  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
