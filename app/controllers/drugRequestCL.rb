require 'net/http'
require 'uri'
require 'nokogiri'

#
# POST-ed FIHR Rx Order XML
#
filename = "RTOP2.xml"
fileXML = File.read(filename)
@requestXMLDoc = Nokogiri::XML(fileXML)
#@requestXMLDoc.remove_namespaces!
medication = @requestXMLDoc.css('/rtop2/soaData/medication')

#
# call patient history lookup
#
_url = "http://10.255.166.15:8080/drugdruginteraction/webresources/drug-interactions/ndc-drug-interactions/"+ medication[0]['code'] + ',' + medication[1]['code']
url = URI.parse(_url)
request = Net::HTTP::Get.new(url.path)
response = Net::HTTP.start(url.host, url.port) { |http| http.request(request) }
puts 'response ---------'
puts response.body.to_s

cleanResponse = response.body.to_s[1..-1].chomp(']')

#
# insert drug warning  into the RTOP2_FIHRRxOrder.xml to form the response back to the message flow
#

soaData = @requestXMLDoc.at_css "soaData"
drugHistoryComment = Nokogiri::XML::Comment.new @requestXMLDoc, ' Medication history from ' + _url
soaData.add_child(drugHistoryComment)
drugDrugInteraction = Nokogiri::XML::Node.new "drugDrugInteraction", @requestXMLDoc
drugDrugInteraction.content= cleanResponse
soaData.add_child(drugDrugInteraction)

puts @requestXMLDoc.to_xml

puts 'Success!'


