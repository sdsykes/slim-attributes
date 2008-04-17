require 'rubygems'
require 'active_record'
require File.dirname(__FILE__) + "/products"
require File.dirname(__FILE__) + "/slim_db_test_utils"

SlimDbTestUtils.connect_and_create_db
Product.create_large_product_table
Product.make_some_products

def do_benchmark(name)
  start_t = Time.now

  2000.times do |n|
    product = Product.find(:all)[n % 100]
    x = product.name
    y = product.comment
    z = product.created_at
  end

  end_t = Time.now
  time_taken = end_t - start_t
  puts "#{name}: #{time_taken}s"
  time_taken
end

time1 = do_benchmark("Without slim-attributes")
require 'slim_attributes'
time2 = do_benchmark("With slim-attributes")
puts "Diff: #{"%.2f"%(100 - time2 / time1 * 100)}%"

SlimDbTestUtils.remove_db
