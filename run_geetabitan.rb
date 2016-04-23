require 'sequel'
require 'pg'
require 'pry'

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

DB.create_table? :index_table do
  primary_key :id

  String :name
  Json :misc_data
  Json :references_data # Form: { table_name_1: id_1, table_name_2, id_2 }
end

DB.create_table? :geetabitan do
  primary_key :id       # TODO: Set autoincrement to true somehow
  String :letter

  # Main section
  String :link, unique: true
  String :english_name, unique: true
  String :bengali_name, null: false
  Text :lyrics

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
  String :notation

  # Staff notation section
  String :staff_notation_pdf
  String :staff_notation_midi

  # English lyric and translation
  Text :english_lyrics
  Text :english_translation

  # Audio
  # String :audio

  # Misc
  Json :misc_data
end

# Reqruire
require_relative 'geetabitan.com/scraper.rb'
