# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-tag/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-tag'
  spec.version       = CocoapodsTag::VERSION
  spec.authors       = ['Jensen']
  spec.email         = ['zys2@meitu.com']
  spec.description   = %q{方便地帮助pod库打tag的CocoaPods插件}
  spec.summary       = %q{方便地帮助pod库打tag的CocoaPods插件，可以校验podspec的合法性}
  spec.homepage      = 'https://github.com/Zhangyanshen/cocoapods-tag.git'
  spec.license       = 'MIT'

  spec.files = Dir["lib/**/*.rb","spec/**/*.rb"] + %w{README.md LICENSE.txt }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'cocoapods'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
