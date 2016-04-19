require 'sequel'
require 'pg'
require 'pry'

# Reqruire
require_relative 'geetabitan.com/scraper.rb'

# Database information
info = {
  host: 'localhost',
  user: 'robindro',
  password: '',
  database: 'robindro'
}

# Include postgres and use additional postgres features
DB = Sequel.postgres(info)
DB.extension :pg_array, :pg_json

DB.create_table :index_table do
  String :name
  Json :misc_data
  Json :references_data # Form: { table_name_1: id_1, table_name_2, id_2 }
end

DB.create_table :geetabitan do
  primary_key :id       # TODO: Set autoincrement to true somehow

  # Main section
  String :name
  Text :lyric

  # About section
  String :parjaay
  String :taal
  String :raag
  String :written_on
  String :notes
  String :place
  String :collection
  String :book

  # Notation section

  # Staff notation section

  # English lyric and translation
  Text :english_lyric
  Text :english_translation

  # Misc
  Json :misc_data
end

binding.pry
