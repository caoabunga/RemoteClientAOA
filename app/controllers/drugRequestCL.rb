require 'net/http'
require 'uri'
require 'nokogiri'

@error = 'Success!'
@DRUG_DRUG_INTERACTION = "http://10.255.166.15:8080/drugdruginteraction/webresources/drug-interactions/ndc-drug-interactions/"

def do_get (urlString)
  url = URI.parse(urlString)
  http = Net::HTTP.new(url.host, url.port)
  http.open_timeout = 10
  http.read_timeout = 10
  response = http.start do |http|
    http.request_get(url.path)
  end
  response.body
end

#
# POST-ed FIHR Rx Order XML
#
filename = "RTOP2.xml"
fileXML = File.read(filename)
@requestXMLDoc = Nokogiri::XML(fileXML)
#@requestXMLDoc.remove_namespaces!
medication = @requestXMLDoc.css('/rtop2/soaData/medication')

begin
#
# call patient history lookup
#
  urlString = @DRUG_DRUG_INTERACTION + medication[0]['code'] + ',' + medication[1]['code']
  responseBody = do_get(urlString)
  #puts 'response ---------'
  p responseBody.to_s
  #puts responseBody.to_s
  drugDrugResponseBodyMessage = responseBody.to_s[1..-1].chomp(']')

#
# insert drug warning  into the RTOP2_FIHRRxOrder.xml to form the response back to the message flow
#

  soaData = @requestXMLDoc.at_css "soaData"
  drugHistoryComment = Nokogiri::XML::Comment.new @requestXMLDoc, ' Medication history from ' + @DRUG_DRUG_INTERACTION
  soaData.add_child(drugHistoryComment)
  drugDrugInteraction = Nokogiri::XML::Node.new "drugDrugInteraction", @requestXMLDoc
  drugDrugInteraction.content= drugDrugResponseBodyMessage
  soaData.add_child(drugDrugInteraction)
rescue Exception => e
  soaData = @requestXMLDoc.at_css "soaData"
  errorFromGlueService = Nokogiri::XML::Node.new "errorFromGlueService", @requestXMLDoc
  errorFromGlueService.content = e.message
  soaData.add_child(errorFromGlueService)
  @error = 'Failed ' + e.message
end

puts @requestXMLDoc.to_xml

puts @error


