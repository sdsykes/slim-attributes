# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{slim-attributes}
  s.version = "0.6.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Stephen Sykes"]
  s.date = %q{2009-04-07}
  s.description = %q{Slim attributes boosts speed in Rails/Mysql ActiveRecord Models by avoiding instantiating Hashes for each result row, and lazily instantiating attributes as needed.}
  s.email = %q{sdsykes@gmail.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["MIT_LICENCE", "Rakefile", "README", "VERSION.yml", "ext/extconf.rb", "ext/slim_attrib_ext.c", "lib/slim_attributes.rb", "test/benchmark.rb", "test/database.yml", "test/products.rb", "test/slim_attributes_test.rb", "test/slim_db_test_utils.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/sdsykes/slim-attributes}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Slim-attributes - lazy instantiation of attributes for ActiveRecord}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
