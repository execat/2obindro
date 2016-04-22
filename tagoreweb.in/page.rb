require 'httparty'
require 'nokogiri'
require 'json'
require 'pry'
require 'csv'

# This class defines rules for scraping content off a poem page

class Page
  def initialize(name, link, params = {})
    @name = name
    @link = link
    @params = params
    @errors = []
  end

  def result
    return puts(@errors) || { misc_data: Sequel.pg_json({ errors: @errors }) } unless fetch
    {
      link: full_link,
      number: fetch_number,
      name: fetch_title,
      parjaay: fetch_parjaay,
      lyrics: fetch_lyrics,
      misc_data: Sequel.pg_json({
        bow: count_words(fetch_lyrics),
        html: fetch && page.to_html,
        about_raw: about_hash,
        errors: @errors,
      }),
    }.merge(fetch_about)
  end

  # private
  attr_accessor :link, :name, :params, :data, :page

  def full_link
    @_full_link ||= URI::join(params[:current_url], link).to_s
  end

  def fetch
    @data ||= HTTParty.get(full_link)
    if @data.code != 200
      @errors << [{ link: link, error: "Response was incorrect", response: @data.code}]
      @errors = @errors.uniq
      return nil
    end
    @page ||= Nokogiri::HTML(data)
  end

  def fetch_number
    fetch &&
      page.at_css(".rightBottom1 h2 span.bn").text
  end

  def fetch_title
    name.split(':').first.strip
  end

  def fetch_parjaay
    name.split(':').last.strip
  end

  # Used by lyrics and about
  def fetch_content
    # count = 2 [lyrics, metadata]
    page.css(".rightBottom1 .content").xpath("./table").css("td")
  end

  def fetch_lyrics
    fetch &&
      fetch_content.first.text
  end

  def accepted_keys
    [
      "রাগ", "তাল", "রচনাকাল (বঙ্গাব্দ)", "রচনাকাল (খৃষ্টাব্দ)", "রচনাস্থান", "স্বরলিপিকার"
    ]
  end

  def transform
    {
      "রাগ" => "raag",
      "তাল" => "taal",
      "রচনাকাল (বঙ্গাব্দ)" => "written_on_bengali",
      "রচনাকাল (খৃষ্টাব্দ)" => "written_on_gregorian",
      "রচনাস্থান" => "place",
      "স্বরলিপিকার" => "music",
    }
  end

  def fetch_about
    # Filter by keys for which columns exist in the schema from setup.rb
    filtered_hash = about_hash.select { |key, _| accepted_keys.include? key }
    # Rename from Bengali to English
    filtered_hash.keys.each do |key|
      filtered_hash[transform[key]] = filtered_hash[key]
      filtered_hash.delete(key)
    end
    filtered_hash
  end

  def about_hash
    result = {}
    # Split by newline and create a hash with key and value
    about = fetch &&
      fetch_content.last.css("span").map { |string| string.text }
    about.each do |elements|
      element = elements.split(":")
      @errors << [{ name: fetch_title, about: about }] && @errors = @errors.uniq if element.count != 2

      key = element[0].downcase.strip
      value = element[1] || ""
      value = value.to_bn if /রচনাকাল/ =~ key
      result[key] = value.strip
    end
    result
  end

  # Count words
  def count_words string
    return nil unless string
    words = string.gsub(/\s+/, ' ').split(/[\s,']/).map(&:strip)
    frequency = Hash.new(0)
    words.each { |word| frequency[word.downcase] += 1 }
    Hash[frequency.sort_by { |_, value| value }.reverse]
  end
end
