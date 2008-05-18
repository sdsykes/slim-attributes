Gem::Specification.new do |s|
  s.name = 'slim-attributes'
  s.version = "0.4"
  s.platform = Gem::Platform::RUBY
  s.summary = <<-DESC.strip.gsub(/\n\s+/, " ")
    Slim attributes boosts speed in Rails/Mysql ActiveRecord Models by avoiding
    instantiating Hashes for each result row, and lazily instantiating attributes as needed
  DESC
  s.files = Dir.glob("{lib,ext}/**/*") + %w(README MIT_LICENCE)
  s.require_path = 'lib'
  s.has_rdoc = false
  s.bindir = "bin"
  s.author = "Stephen Sykes"
  s.email = "sdsykes@gmail.com"
  s.homepage = "http://slim-attributes.rubyforge.org/"
  s.rubyforge_project = "slim-attributes"
  s.autorequire = "slim"
  s.extensions = "ext/extconf.rb"
end
