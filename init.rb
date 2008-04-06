if RunningOn.server? || RunningOn.sds_laptop?
  ActiveRecord::Base.require_mysql
  class Mysql::Result; class FakeResultHash; end; end
  require 'SlimAttributes'
  require 'slim'
end

