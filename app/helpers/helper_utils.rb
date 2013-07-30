require 'net/http'
require 'uri'
require 'nokogiri'

module HelperUtils
  def self.do_post (_urlString, post_xml)
    url = URI.parse(_urlString)
    http = Net::HTTP.new(url.host, url.port)
    http.open_timeout = 60
    http.read_timeout = 60
    response = http.start do |http|
      http.post(url.path, post_xml, {'Content-Type' =>'application/xml'})
    end
    response.body
  end
  def self.do_get (urlString)
    url = URI.parse(urlString)
    http = Net::HTTP.new(url.host, url.port)
    http.open_timeout = 10
    http.read_timeout = 10
    response = http.start do |http|
      http.request_get(url.path)
    end
    response.body
  end

  def self.outputPayload (filename, requestXML)
    
    filename = File.join(Rails.root, 'public', 'payload-files', filename)
      File.open(filename, 'w') do |f|
      f.puts requestXML
    end
  end

end