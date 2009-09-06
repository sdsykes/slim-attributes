# Author: Stephen Sykes
# http://pennysmalls.com

require 'rubygems'
require 'active_record'
require 'active_record/version'
require 'slim_attributes'
require 'test/unit'
require File.dirname(__FILE__) + "/products"
require File.dirname(__FILE__) + "/slim_db_test_utils"

class SlimAttributesTest < Test::Unit::TestCase
  def setup
    SlimDbTestUtils.connect_and_create_db
    Product.create_product_table
    Product.make_some_products
  end

  def test_finds_all
    items = Product.find(:all)
    assert items.size == 100, "must find all 100 items"
  end

  def test_items_have_correct_attributes
    items = Product.find(:all, :order=>"id")
    items.each_index do |i|
      check_attributes_for(items[i], i)
    end
  end

  def test_item_attributes_can_be_changed
    item = Product.find(:first)
    old_name = item.name.dup
    item.name << "more"
    assert_equal old_name + "more", item.name, "change must stick"
    item.nil_test = "not a nil"
    assert_equal "not a nil", item.nil_test, "change must stick"
    item.name = "something else"
    assert_equal "something else", item.name, "change must stick"
    item.save
    item = Product.find(:first)
    assert_equal "something else", item.name, "change must persist in DB"
    assert_equal "not a nil", item.nil_test, "change must persist in DB"
  end

  def test_item_attributes_to_a_works
    item = Product.find_by_id(1)
    arr = item.attributes_iv.to_a
    expected = [["id","1"], ["name", "product_0"], ["number","0"], ["comment","Made by the test suite"], ["created_at", item.created_at_before_type_cast], ["nil_test", nil]]
    arr.each do |a|
      assert expected.include?(a), "array must match"
    end
  end

  def test_item_can_be_marshalled
    item = Product.find_by_id(1)
    mi = Marshal.load(Marshal.dump(item))
    check_attributes_for(mi, 0)
  end
  
  def test_has_key_and_include
    item = Product.find_by_id(1)
    assert item.attributes_iv.has_key?("name"), "must have key name"
    assert item.attributes_iv.include?("name"), "must have key name"
    assert !item.attributes_iv.has_key?("name1"), "must not have key name1"
    assert !item.attributes_iv.include?("name1"), "must not have key name1"
  end

  def test_keys
    item = Product.find_by_id(1)
    assert_equal ["id", "name", "created_at", "number", "comment", "nil_test"].sort, item.attributes_iv.keys.sort, "keys must work"
  end

  def test_to_hash
    item = Product.find_by_id(1)
    expected = {"id"=>"1", "name"=>"product_0", "number"=>"0", "comment"=>"Made by the test suite", "created_at"=>item.created_at_before_type_cast, "nil_test"=>nil}
    hash = item.attributes_iv.to_hash
    assert_equal Hash, hash.class, "to_hash must result in a Hash"
    assert_equal expected, hash, "to_hash must work"
  end
  
  def test_fake_hash_can_be_updated
    item = Product.find_by_id(1)
    old_name = item.name
    item.attributes_iv.update("name"=>"foobar")
    assert_equal "foobar", item.name, "update must work"
    item.name_will_change! if ActiveRecord::VERSION::STRING >= "2.1.0"
    item.save
    item = Product.find_by_id(1)
    assert_equal "foobar", item.name, "update must work and stick through db"
    assert_equal 0, item.number, "other attributes must not be changed in db"
    item.name = old_name
    item.save
  end

  def test_can_assign_to_non_columns_in_hash
    item = Product.find_by_id(1)
    fh = item.attributes_iv
    fh["something"] = 23
    fh[:symbol] = "23"
    assert_equal 23, fh["something"], "assignment to non col"
    assert_equal "23", fh[:symbol], "assignment to non col"
    assert fh.keys.include?("something"), "keys must include new"
    assert fh.keys.include?(:symbol), "keys must include new"
    assert fh.keys.include?("name"), "keys must still include old"
    assert_equal 23, item.something, "non col becomes accessible with method call"
  end

  def test_key_can_be_deleted
    item = Product.find_by_id(1)
    fh = item.attributes_iv
    fh.delete("name")
    assert_nil fh["name"], "name must be nil now"
    assert_raises(ActiveRecord::MissingAttributeError, "name must raise on method call") {item.name}
  end
  
  def test_gc
    GC.start
    assert true, "gc didn't crash"
  end
  
  # rails query cache uses dup
  def test_dup
    items = Product.find(:all)
    attr_dup = items[0].attributes_iv.dup
    assert_equal "product_0", attr_dup["name"], "name must be correct in dup'd attributes"
    attr_dup = items[0].attributes_iv.dup
    assert_equal "product_0", attr_dup["name"], "name must be correct in dup'd attributes 2nd time"
  end

  def test_cached_result
    ActiveRecord::Base.connection.cache do
      item1 = Product.find_by_id(1)
      item1.name = "foo"
      item2 = Product.find_by_id(1)
      assert_equal "product_0", item2.name, "name must be original from cached query"
      item3 = Product.find_by_id(1)
      item1.name = "bar"
      assert_equal "product_0", item3.name, "name must be original from cached query"
      item2.name << "_test"
# unmodified rails fails this test, it's ok
#      check_attributes_for(item3, 0)
    end
  end
  
  def test_accessing_destroyed_object_attributes
    item1 = Product.find_by_id(1)
    assert_equal false, item1.frozen?
    item1.destroy  # object is frozen
    assert_equal true, item1.frozen?
    check_attributes_for(item1, 0)
    assert_raises(RUBY_VERSION >= "1.9" ? RuntimeError : TypeError) {item1.name = "another product"}
  end

  def teardown
    SlimDbTestUtils.remove_db
  end

  private

  def check_attributes_for(item, i)
    assert_equal "product_#{i}", item.name, "item name must be right"
    assert_equal i, item.number, "item number must be right"
    assert_equal i + 1, item.id, "item id must be right"
    assert_equal "Made by the test suite", item.comment, "item comment must be right"
    assert item.created_at <= Time.now && item.created_at > Time.now - 30, "item created_at must be reasonable"
    assert_nil item.nil_test, "nil_test must be nil"
  end
end
