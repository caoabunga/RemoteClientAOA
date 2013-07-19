class HelperUtils
  def intialize
  end
  def do_post (_urlString, post_xml)
    url = URI.parse(_urlString)
    http = Net::HTTP.new(url.host, url.port)
    http.open_timeout = 10
    http.read_timeout = 10
    # FIX ME
    #http.content_type = 'application/xml'
    #http.body = post_xml
    response = http.start do |http|
      http.post(url.path, post_xml, {'Content-Type' =>'application/xml'})
    end
    response.body
  end
end