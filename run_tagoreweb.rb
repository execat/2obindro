require 'sequel'
require 'to_bn'
require 'pg'
require 'pry'

# Database information
info = {
  host: 'localhost',
  user: 'robindro',
  password: '',
  database: 'robindro'
}

puts "Preparing/checking database"

# Include postgres and use additional postgres features
DB = Sequel.postgres(info)
DB.extension :pg_array, :pg_json

DB.create_table? :tagoreweb do
  primary_key :id
  Char :letter, index: true

  # Main section
  String :number, limit: 6
  String :link, unique: true, limit: 1023
  String :name, limit: 127, index: true
  Text :lyrics

  # About section
  String :parjaay, limit: 63, index: true
  String :raag, limit: 63
  String :taal, limit: 63
  String :written_on_bengali, limit: 127
  String :written_on_gregorian, limit: 127
  String :music, limit: 127
  String :place, limit: 127

  # Misc
  Jsonb :misc_data

  # Indexes
  index [:name, :parjaay], unique: true
end

# Require
puts "Calling scraper"
require_relative 'tagoreweb/scraper.rb'
