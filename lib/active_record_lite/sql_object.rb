require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table = table_name
  end

  def self.table_name
    @table.underscore.pluralize
  end

  def self.all
    result = DBConnection.execute("SELECT * FROM #{@table}")
    parse_all(result)
  end

  def attribute_values
    self.class.attributes.map {|attribute| self.send(attribute)}
  end

  def self.find(id)
    result = DBConnection.execute("SELECT * FROM #{@table} WHERE id = #{id}")
    self.new(result[0])
  end

  def create
    question = (["?"] * self.class.attributes.count).join(", ")

    attr_names = self.class.attributes.join(", ")

    # p self
    # p question
    # p attr_names
    # p attribute_values

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO #{self.class.table_name} 
      (#{attr_names})
      VALUES (#{question})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = []

    self.class.attributes.each do |attr_name|
      set_line << "#{attr_name} = ?"
    end



    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE #{self.class.table_name}
      SET #{set_line.join(", ")}
      WHERE id = ?
    SQL

  end

  def save

    if id.nil?
      create
    else
      update
    end
  end

end

