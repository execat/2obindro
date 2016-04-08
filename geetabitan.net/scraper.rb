require 'httparty'
require 'nokogiri'
require 'json'
require 'pry'
require 'csv'

require_relative 'page'

class Scraper
  def scrape
    visit_indexes &&
      visit_pages
  end

  private
  attr_accessor :indexes, :pages

  def visit_indexes
    @indexes = indexes.map do |index|
      # Screen
      print "."
      # Generate base URL to append the parsed links to
      base_url = "http://www.geetabitan.com/lyrics/#{index}"
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
    end.flatten
  end

  def visit_pages
    binding.pry
  end

=begin
  def visit_page(link)
    page = HTTParty.get(link)
    Nokogiri::HTML(page)
  end
=end

  def indexes
    # From http://www.geetabitan.com/lyrics/index.html
    @indexes ||= ["A", "B", "C", "D", "E", "G", "H", "I", "J", "K", "L",
                  "M", "N", "O", "P", "R", "S", "T", "U"]
  end
end

s = Scraper.new
s.scrape
