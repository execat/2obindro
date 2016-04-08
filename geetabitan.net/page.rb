require 'httparty'
require 'nokogiri'
require 'json'
require 'pry'
require 'csv'

# This class defines rules for scraping content off a poem page

class Page
  def initialize(link, params = {})
    @link = link
    @params = params
  end

  def result
    {
      bengali_lyrics: fetch_bengali_lyrics,
      about: fetch_about,
      notation: fetch_notation,
      staff_notation: fetch_staff_notation,
      english_lyrics: fetch_english_lyrics,
      english_translation: fetch_english_translations,
      audio: fetch_audio,
      errors: {
        about: @@errors_about,
      },
    }
  end

  # private
  attr_accessor :link, :params, :data, :page

  def fetch
    @data ||= HTTParty.get(link)
    @page ||= Nokogiri::HTML(data)
  end

  # 0th tab
  def fetch_title
    title = {}
    fetch &&
      page.css(".extra").each do |element|
        title_element = element.next_element
        title[:english] = title_element.css('h2').text.capitalize
        title[:bengali] = title_element.css('h3').text.split(":").last.strip
      end
    {
      english: title[:english],
      bengali: title[:bengali],
    }
  end

  # First tab
  def fetch_bengali_lyrics
    fetch &&
      page.css("#view1").css(".bengly").text
  end

  @@errors_about = []
  # Second tab
  def fetch_about
    result = {}
    about = fetch &&
      page.css("#view2").css(".about").text.strip.split("\n")
    about.each do |elements|
      element = elements.split(":")
      @@errors_about << [{ name: fetch_title, about: about }] if element.count != 2
      result[element[0].downcase.strip] = (element[1] || "").strip
    end
    result
  end

  # Third tab
  def fetch_notation
    fetch &&
      page.css("#view3").text
  end

  # Fourth tab
  def fetch_staff_notation
    fetch &&
      page.css("#view4").text
  end

  # Fifth tab
  def fetch_english_lyrics
    fetch &&
      page.css("#view5").css(".engly").text
  end

  # Sixth tab
  def fetch_english_translations
    fetch &&
      page.css("#view6").css(".transpre").text
  end

  # Seventh tab
  def fetch_audio
    fetch &&
      page.css("#view7").text
  end
end
