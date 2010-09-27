# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{slim-attributes}
  s.version = "0.7.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Stephen Sykes"]
  s.date = %q{2010-09-27}
  s.description = %q{Slim attributes boosts speed in Rails/Mysql ActiveRecord Models by avoiding
    instantiating Hashes for each result row, and lazily instantiating attributes as needed.}
  s.email = %q{sdsykes@gmail.com}
  s.extensions = ["ext/extconf.rb"]
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    "MIT_LICENCE",
     "README",
     "Rakefile",
     "VERSION.yml",
     "ext/extconf.rb",
     "ext/slim_attrib_ext.c",
     "lib/slim-attributes.rb",
     "lib/slim_attributes.rb",
     "test/benchmark.rb",
     "test/database.yml",
     "test/products.rb",
     "test/slim_attributes_test.rb",
     "test/slim_db_test_utils.rb"
  ]
  s.homepage = %q{http://github.com/sdsykes/slim-attributes}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{slim-attributes}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Slim-attributes - lazy instantiation of attributes for ActiveRecord}
  s.test_files = [
    "test/benchmark.rb",
     "test/products.rb",
     "test/slim_attributes_test.rb",
     "test/slim_db_test_utils.rb"
  ]
  s.add_dependency('mysql')
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

