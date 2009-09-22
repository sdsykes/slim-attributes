# this code was originally borrowed from Mysql/Ruby, credit to TOMITA Masahiro
# it works for me under OS X and Fedora, hope it works for you also

require 'mkmf'

# Improved detection of mysql_config
# Code from DataObjects do_mysql adapter
# All instances of mysql_config on PATH ...
def mysql_config_paths
  ENV['PATH'].split(File::PATH_SEPARATOR).collect do |path|
    [ "#{path}/mysql_config", "#{path}/mysql_config5" ].
      detect { |bin| File.exist?(bin) }
  end
end

# The first mysql_config binary on PATH ...
def default_mysql_config_path
  mysql_config_paths.compact.first
end

if /mswin32/ =~ RUBY_PLATFORM
  inc, lib = dir_config('mysql')
  exit 1 unless have_library("libmysql")
elsif mc = with_config('mysql-config', default_mysql_config_path) then
  mc = 'mysql_config' if mc == true
  cflags = `#{mc} --cflags`.chomp
  exit 1 if $? != 0
  libs = `#{mc} --libs`.chomp
  exit 1 if $? != 0
  $CPPFLAGS += ' ' + cflags
  $libs = libs + " " + $libs
else
  inc, lib = dir_config('mysql', '/usr/local')
  libs = ['m', 'z', 'socket', 'nsl', 'mygcc']
  while not find_library('mysqlclient', 'mysql_query', lib, "#{lib}/mysql") do
    exit 1 if libs.empty?
    have_library(libs.shift)
  end
end

create_makefile("slim_attrib_ext")
