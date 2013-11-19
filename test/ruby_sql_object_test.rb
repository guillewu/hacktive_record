require_relative '../lib/active_record_lite'

# https://tomafro.net/2010/01/tip-relative-paths-with-file-expand-path
cats_db_file_name =
  File.expand_path(File.join(File.dirname(__FILE__), "cats.db"))
DBConnection.open(cats_db_file_name)

class Cat < SQLObject
  set_table_name("cats")
  my_attr_accessible(:id, :name, :owner_id)
end

class Human < SQLObject
  set_table_name("humans")
  my_attr_accessible(:id, :fname, :lname, :house_id)
end

p Human.find(1)
p Cat.find(1)
p Cat.find(2)

p Human.all
p Cat.all

# c = Cat.new(:name => "Gizmo", :owner_id => 1)
# c.save


h = Human.find(1)

# just run an UPDATE; no values changed, so shouldnt hurt the db
h.save
