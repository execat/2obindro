require 'httparty'
require 'nokogiri'
require 'json'
require 'pry'

module TagoreWeb
end

class TagoreWeb::Scraper
  def scrape
    visit_indexes
    # && ...
  end

  private
  def index_links
    @_index_links ||=
      ["Verses", "Songs", "Novels", "Stories", "Plays", "Essays", "Others"].map do |suffix|
        "http://www.tagoreweb.in/Render/ShowContentType.aspx?ct=#{suffix}"
      end
  end
end

s = Scraper.new
s.scrape
