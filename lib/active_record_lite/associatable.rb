require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader :other_class_name, :primary_key, :foreign_key

  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @other_class_name = params[:class_name] || name.to_s.camelcase
    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{name}_id"
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @other_class_name = params[:class_name] || name.to_s.singularize.camelcase
    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{self_class}_id"
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
    @assoc_params
  end

  def belongs_to(name, params = {})
    assoc = BelongsToAssocParams.new(name, params)
    assoc_params[name] = assoc

    define_method(name) do
      result = DBConnection.execute(<<-SQL, self.send(assoc.foreign_key))
        SELECT * 
        FROM #{assoc.other_table}
        WHERE #{assoc.primary_key} = ?
      SQL

      assoc.other_class.parse_all(result)[0]
    end
  end

  def has_many(name, params = {})
    assoc = HasManyAssocParams.new(name, params, self)
    assoc_params[name] = assoc

    define_method(name) do
      result = DBConnection.execute(<<-SQL, self.send(assoc.primary_key))
        SELECT *
        FROM #{assoc.other_table}
        WHERE #{assoc.foreign_key} = ?
      SQL

      assoc.other_class.parse_all(result)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      params1 = self.class.assoc_params[assoc1]
      params2 = params1.other_class.assoc_params[assoc2]

      results = DBConnection.execute(<<-SQL, self.send(params1.foreign_key))
        SELECT #{params2.other_table}.*
        FROM #{params1.other_table}
        JOIN #{params2.other_table}
        ON #{params1.other_table}.#{params2.foreign_key}
          = #{params2.other_table}.#{params2.primary_key}
        WHERE #{params1.other_table}.#{params1.primary_key} = ?
      SQL

      params2.other_class.parse_all(results)[0]
    end
  end
end
