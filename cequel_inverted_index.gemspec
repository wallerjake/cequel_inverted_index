lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cequel_inverted_index/version'

Gem::Specification.new do |spec|
  spec.name          = 'cequel_inverted_index'
  spec.version       = CequelInvertedIndex::VERSION
  spec.authors       = ['Clark Bremer']
  spec.email         = ['clarkbremer@gmail.com']
  spec.description   = 'Rails Generator to create Cequel Inverted Indecies'
  spec.summary       = ''
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'cequel', '>= 1.5'
end
