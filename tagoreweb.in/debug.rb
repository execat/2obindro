require 'httparty'
require 'nokogiri'
require 'json'
require 'pry'
require 'sequel'
require 'to_bn'
require 'pg'
require 'pry'

require_relative 'page'

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

data = File.open("data.1461332498.marshal", "r") do |from_file|
  Marshal.load(from_file)
end[:data]

binding.pry
