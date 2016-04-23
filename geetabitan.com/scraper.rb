require 'httparty'
require 'nokogiri'
require 'json'
require 'pry'
require 'sequel'

require_relative 'page'

module Geetabitan
end

class Geetabitan::Scraper
  def scrape
    visit_indexes &&
      visit_pages
  end

  private
  attr_accessor :song_list, :songs

  def database
    return @_database[:geetabitan] if @_database

    # Include postgres and use additional postgres features
    @_database = Sequel.postgres(database_info)
    @_database.extension :pg_array, :pg_json
    @_database[:geetabitan]
  end

  def database_info
    @_info = {
      host: 'localhost',
      user: 'robindro',
      password: '',
      database: 'robindro'
    }
  end

  def visit_indexes
    total = indexes.length
    @song_list = indexes.each_with_index.map do |index, i|
      # Screen
      puts "Index #{index} (#{i + 1}/#{total})"
      # Generate base URL to append the parsed links to
      base_url = "http://www.geetabitan.com/lyrics/#{index}"
      # View source of http://www.geetabitan.com/lyrics/A/song-list.html
      link = "http://www.geetabitan.com/lyrics/js/list-#{index.downcase}.js"
      page = HTTParty.get(link)
      a = page.to_s.
        # Remove JavaScript document.write functions
        gsub(/document.write\(\"/, "").
        gsub(/\);/, "").
        # Remove double escapes
        gsub(/\\/, "")
      Nokogiri::HTML(a).
        css('a').map do |index_entry|
        text = index_entry.text
        link = index_entry.attribute("href").text
        {
          letter: index,
          text: text,
          link: "#{base_url}/#{link}",
        }
      end
    end
  end

  def visit_pages
    list = song_list.flatten
    total = list.length
    @songs = list.each_with_index.map do |song, i|
      puts "Song #{song[:text]} (#{i + 1}/#{total})"
      link = song.delete(:link)
      song = Page.new(link, song).result
      begin
        database.insert(song)
      rescue Exception => ex
        puts ex
        puts "ERROR: #{song[:text]}"
      end
      sleep 0.1
      song
    end
  end

  def indexes
    # From http://www.geetabitan.com/lyrics/index.html
    @indexes ||= ["A", "B", "C", "D", "E", "G", "H", "I", "J", "K", "L",
                  "M", "N", "O", "P", "R", "S", "T", "U"]
  end
end

s = Geetabitan::Scraper.new
s.scrape
File.open("tmp/data.geetabitan.#{Time.now.to_i}.marshal", "w") do |to_file|
  Marshal.dump({ data: s.send(:songs)}, to_file)
end
