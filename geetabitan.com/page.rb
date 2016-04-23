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
    @current_link = params[:current_link]
    @errors = []
  end

  def result
    return puts(@errors) || { misc_data: Sequel.pg_json({ errors: @errors }) } unless fetch
    {
      link: link,
      letter: fetch_title[:english][0].upcase,
      english_name: fetch_title[:english],
      bengali_name: fetch_title[:bengali],
      lyrics: fetch_bengali_lyrics,
      notation: fetch_notation,
      staff_notation_pdf: fetch_staff_notation && fetch_staff_notation[:pdf],
      staff_notation_midi: fetch_staff_notation && fetch_staff_notation[:midi],
      english_lyrics: fetch_english_lyrics,
      english_translation: fetch_english_translations,
      misc_data: Sequel.pg_json({
        bengali_bow: count_words(fetch_bengali_lyrics),
        english_bow: count_words(fetch_english_lyrics),
        english_trans_bow: count_words(fetch_english_translations),
        html: fetch && page.to_html,
        about_raw: fetch_about_raw,
        errors: @errors,
      }),
    }.merge(fetch_about)
  end

  # private
  attr_accessor :link, :params, :data, :page, :current_link

  def fetch
    @data ||= HTTParty.get(link)
    if @data.code != 200
      @errors << [{ link: link, error: "Response was incorrect", response: @data.code}]
      @errors = @errors.uniq
      return nil
    end
    @page ||= Nokogiri::HTML(data)
  end

  # 0th tab
  def fetch_title
    title = {}
    title_element = fetch &&
      page.at_css(".extra").next_element
    title[:english] = title_element.at_css('h2').text.capitalize
    title[:bengali] = title_element.at_css('h3').text.split(":").last.strip
    # Exception
    if link == "http://www.geetabitan.com/lyrics/A/ananter-baani-tumi.html"
      title[:english] = "Ananter Baani Tumi"
    end
    {
      english: title[:english],
      bengali: title[:bengali],
    }
  end

  # First tab
  def fetch_bengali_lyrics
    fetch &&
      page.at_css("#view1 .bengly").text
  end

  # Second tab
  def accepted_keys
    [:parjaay, :taal, :raag, :written_on, :notes, :place, :collection, :book]
  end

  def fetch_about_raw
    # Filter by keys for which columns do not exist in the schema from setup.rb
    about_hash.reject { |key, _| accepted_keys.include? key }
  end

  def fetch_about
    # Filter by keys for which columns exist in the schema from setup.rb
    about_hash.select { |key, _| accepted_keys.include? key }
  end

  def about_hash
    result = {}
    # Split by newline and create a hash with key and value
    about = fetch &&
      page.at_css("#view2 .about").text.strip.split("\n")
    about.each do |elements|
      element = elements.split(":")
      @errors << [{ name: fetch_title, about: about }] && @errors = @errors.uniq if element.count != 2
      result[element[0].downcase.strip.gsub(/ /, "_").to_sym] = (element[1] || "").strip
    end
    result
  end

  # Third tab
  def fetch_notation
    relative_url = fetch &&
      element = page.at_css("#view3 img") &&
      element &&
      link = element.attribute("src") &&
      link && link.text.gsub(/ /, "")
    return nil unless relative_url
    URI::join(link, relative_url).to_s
  end

  # Fourth tab
  def fetch_staff_notation
    element = fetch &&
      item = page.at_css("#view4 ul") && item && item.css("a")
    return nil unless element && element.count >= 2
    urls = element.map { |l| l.attribute("href").text }
    pdf_url = URI::join(link, urls.select { |u| u =~ /pdf/ }.first)
    midi_url = URI::join(link, urls.select { |u| u =~ /\.mid/ }.first)
    {
      pdf_url: pdf_url,
      midi_url: midi_url
    }
  end

  # Fifth tab
  def fetch_english_lyrics
    fetch &&
      page.at_css("#view5 .engly").text
  end

  # Sixth tab
  def fetch_english_translations
    fetch &&
      # page.at_css("#view6").at_css(".transpre").text
      # nil if empty
      html = page.at_css("#view6 .transpre") && html && html.text
  end

  # Seventh tab
  def fetch_audio
    fetch &&
      page.at_css("#view7").text
  end

  # Count words
  def count_words string
    return nil unless string
    words = string.gsub(/\s+/, ' ').split(/[\s,']/)
    frequency = Hash.new(0)
    words.each { |word| frequency[word.downcase] += 1 }
    frequency
  end
end
