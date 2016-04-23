require 'httparty'
require 'nokogiri'
require 'json'
require 'pry'
require 'sequel'

require_relative 'page'

module Tagoreweb
end

class Tagoreweb::Scraper
  def scrape
    visit_index &&
      visit_pages
  end

  private
  attr_accessor :song_list, :songs, :total, :current_index

  def database
    return @_database if @_database
    @_database = Sequel.postgres(database_info)
    @_database.extension :pg_array, :pg_json
    @_database
  end

  def table
    database[:tagoreweb]
  end

  def database_info
    @_info = {
      host: 'localhost',
      user: 'robindro',
      password: '',
      database: 'robindro'
    }
  end

  def index_link
    @_index_link = "http://www.tagoreweb.in/StaticTOC/AlphabeticSongsIndex.aspx?ct=Songs"
  end

  # {
  #   a: { text1: link1, text2: link2,... },
  #   b: { text1: link1, text2: link2,... },
  #   :
  # }
  def visit_index
    puts "Fetching index"
    page = HTTParty.get(index_link)
    total = 0
    list = Nokogiri::HTML(page.to_s).at_css("table.bn").
      xpath("./tr").each_with_index.map do |row, i|
        # Skip first tr because it is the index
        next if i == 0
        letter = row.at_css("h3").text
        rows = row.at_css("table").css("td")
        pairs = rows.map do |entry|
          puts "Fetching #{entry.text}"
          begin
            total += 1
            [entry.text, entry.at_css("a").attribute("href").to_s]
          rescue
            nil
          end
        end
        { letter => Hash[pairs.compact] }
      end
    @total = total
    @current_index = 0
    @song_list = list.compact
  end

  def visit_pages
    @songs = song_list.map do |hash|
      hash.map do |letter, body|
        puts "\nFetching letter #{letter} \n"
        size = body.count
        body.each_with_index.map do |pair, i|
          name = pair.first
          link = pair.last
          @current_index += 1
          puts "Link #{name} at #{link} (#{i+1}/#{size}) [#{current_index}/#{total}]"
          song = Page.new(name, link, { current_url: index_link }).result
          begin
            table.insert(song.merge({ letter: letter }))
          rescue Exception => ex
            puts ex
            puts "ERROR: #{song[:text]}"
          end
          song
        end
      end
    end
  end
end

s = Tagoreweb::Scraper.new
s.scrape
puts "Marshall all data"
File.open("tmp/data.tagoreweb.#{Time.now.to_i}.marshal", "w") do |to_file|
  Marshal.dump({ data: s.send(:songs)}, to_file)
end
