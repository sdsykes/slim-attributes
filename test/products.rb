# Author: Stephen Sykes
# http://pennysmalls.com

class Product < ActiveRecord::Base
  
  def self.create_product_table
    ActiveRecord::Base.connection.drop_table(:products) rescue ActiveRecord::StatementInvalid
    ActiveRecord::Base.connection.create_table(:products) do |t|
      t.column :name, :string, :limit => 60
      t.column :created_at, :datetime
      t.column :number, :integer
      t.column :nil_test, :string
      t.column :comment, :text
    end
  end

  def self.create_large_product_table
    ActiveRecord::Base.connection.drop_table(:products) rescue ActiveRecord::StatementInvalid
    ActiveRecord::Base.connection.create_table(:products) do |t|
      t.column :name, :string, :limit => 60
      t.column :created_at, :datetime
      t.column :number, :integer
      t.column :nil_test, :string
      t.column :comment, :text
      40.times {|n| t.column "test_col_#{n}", :string}
    end
  end


  def self.make_some_products
    100.times do |n|
      Product.create(:name=>"product_#{n}", :number=>n, :comment=>"Made by the test suite")
    end
  end
  
  def attributes_iv
    @attributes
  end

end
