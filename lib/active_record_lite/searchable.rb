require_relative './db_connection'

module Searchable
  def where(params)
    keys = []
    params.each do |key, value|
      keys << "#{key} = ?"
    end

    result = DBConnection.execute(<<-SQL, *params.values)
    SELECT * 
    FROM #{@table}
    WHERE #{keys.join(" AND ")}
    SQL

    parse_all(result)
  end
end