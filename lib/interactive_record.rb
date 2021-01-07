require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true

        sql = "pragma table_info('#{table_name}')"

        table_info = DB[:conn].execute(sql)
        column_names = []
        table_info.each do |row|
            column_names << row["name"]
        end
        column_names.compact
    end

    def initialize(options={})
        options.each do |k, v|
            self.send("#{k}=", v)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|c| c == "id"}.join(", ")
    end

    def values_for_insert
        v = []
        self.class.column_names.each do |c|
            v << "'#{send(c)}'" unless send(c).nil?
        end
        v.join(", ")
    end

    def save
        sql = <<-SQL 
            INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) 
            VALUES (#{values_for_insert})
        SQL

        DB[:conn].execute(sql)

        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = <<-SQL
            SELECT * FROM #{table_name}
            WHERE name = ?
            LIMIT 1
        SQL

        DB[:conn].execute(sql, name)
    end

    def self.find_by(criteria)
        key = criteria.keys.first
        value = criteria.values.first
        sql = <<-SQL
            SELECT * FROM #{table_name}
            WHERE #{key} = '#{value}'
        SQL
        DB[:conn].execute(sql)
    end
end