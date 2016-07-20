MRuby::Gem::Specification.new('rilo') do |spec|
  spec.license = 'MIT'
  spec.author  = 'ksss'
  spec.summary = 'simple text editor'
  spec.bins = %w(rilo)
  spec.add_dependency('mruby-io-console')
end
