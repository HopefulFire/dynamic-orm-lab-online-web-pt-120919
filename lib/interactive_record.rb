require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

	def self.table_name
		self.to_s.downcase.pluralize
	end

	def self.column_names
		sql = "PRAGMA table_info(#{self.table_name});"

		DB[:conn].execute(sql).map do |column|
			column['name']
		end.compact
	end

	def initialize(options = {})
		options.each do |property, value|
			self.send("#{property}=", value)
		end
	end

	def table_name_for_insert
		self.class.table_name
	end

	def col_names_for_insert
		self.class.column_names.delete_if do |col|
			col == 'id'
		end.join(', ')
	end

	def values_for_insert
		self.class.column_names.map do |col_name|
			"'#{send(col_name)}'" unless send(col_name).nil?
		end.compact.join(', ')
	end

	def save
		sql = <<-SQL
			INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
			VALUES (#{values_for_insert});
		SQL
		DB[:conn].execute(sql)

		sql = <<-SQL
			SELECT last_insert_rowid()
			FROM #{table_name_for_insert};
		SQL
		@id = DB[:conn].execute(sql)[0][0]
	end

	def self.find_by_name(name)
		sql = <<-SQL
			SELECT *
			FROM #{self.table_name}
			WHERE name = "#{name}"
		SQL
		DB[:conn].execute(sql)
	end

	def self.find_by(attribute_hash)
		key = attribute_hash.keys.first
		value = attribute_hash[key]
		value = "'#{value}'" if value.class == String
		sql = <<-SQL
			SELECT *
			FROM #{self.table_name}
			WHERE #{key} = #{value}
		SQL
		DB[:conn].execute(sql)
	end

end