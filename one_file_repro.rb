require 'active_record'
require 'pg'
require 'active_record_inherit_assoc'

# set up database
PG_SPEC = {
  adapter:  'postgresql',
  database: 'inherit_test_db'
}

ActiveRecord::Base.establish_connection(PG_SPEC.merge('database' => 'postgres', 'schema_search_path' => 'public'))
ActiveRecord::Base.connection.drop_database PG_SPEC[:database] rescue nil
ActiveRecord::Base.connection.create_database(PG_SPEC[:database])
ActiveRecord::Base.establish_connection(PG_SPEC)

# Set active record logger to STDOUT to see executed SQL
ActiveRecord::Base.logger = Logger.new(STDOUT)

# define migration to set schema
class CreateModels < ActiveRecord::Migration
  def self.change
    create_table :incoming_conversions do |t|
      t.integer :account_id
      t.string :external_id

      t.timestamps
    end

    create_table :resources do |t|
      t.integer :account_id
      t.string :external_id

      t.timestamps
    end
	end
end

# run migrations
CreateModels.change

# define models and populate db
class IncomingConversion < ActiveRecord::Base
  has_one :resource, primary_key: :external_id, foreign_key: :external_id
  #inherits_from :resource, :attr => [:account_id]
end

class Resource < ActiveRecord::Base
  belongs_to :incoming_conversion, primary_key: :external_id, foreign_key: :external_id
  #inherits_from :incoming_conversion, :attr => [:account_id]
end

# Repro issue

ic = IncomingConversion.create!(external_id: '123', account_id: 1)
r  = Resource.create!(external_id: '123', account_id: 1)

puts '---------'
ic.resource.account_id
puts '---------'

ic_2 = IncomingConversion.create!(external_id: '456', account_id: 2)
r_2  = Resource.create!(external_id: '456', account_id: 2)

#require 'byebug'; byebug

# This should return r_2, it returns r
puts ic_2.resource.account_id.inspect
