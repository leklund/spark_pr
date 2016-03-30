# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spark_pr/version'

Gem::Specification.new do |spec|
  spec.name          = "spark_pr"
  spec.version       = SparkPr::VERSION
  spec.authors       = ["Thomas Fuchs", "Rob Biedenharn", "Lukas Eklund"]
  spec.email         = ["leklund@gmail.com"]

  spec.summary       = %q{Pure Ruby sparkline graph generator with PNG or ASCII output}
  spec.description   = %q{spark_pr is a Ruby class to generate sparkline graphs with PNG or ASCII output. It only depends on zlib and generates PNGs with pure Ruby code. The line-graph outputs antialised lines.}
  spec.homepage      = "https://github.com/leklund/spark_pr"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
