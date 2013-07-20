module Helperutils
  def self.do_post (_urlString, post_xml)
=begin
    url = URI.parse(_urlString)
    http = Net::HTTP.new(url.host, url.port)
    http.open_timeout = 60
    http.read_timeout = 60
    response = http.start do |http|
      http.post(url.path, post_xml, {'Content-Type' =>'application/xml'})
    end
    response.body
=end
  p 'helwhee'
  end
end