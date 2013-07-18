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
return
cleanResponse = response.body.to_s[1..-1].chomp(']')

=begin
filename = "medicationResponse.xml"
file_content = File.read(filename)
cleanResponse = Nokogiri::XML(file_content)
=end

#
# TODO extract medications
#
firstXML, *lastXML = cleanResponse.split(/, /)
puts firstXML
puts *lastXML

@firstXML = Nokogiri::XML(firstXML)
@firstXML.remove_namespaces!

#
# insert medications into the FIHRRxOrder.xml to form the response back to the message flow
#

soaData = @requestXMLDoc.at_css "soaData"
medicationHistoryComment = Nokogiri::XML::Comment.new @requestXMLDoc, ' Medication history from endpoint/patienthistory/webresources/patient-history-lookup  '
soaData.add_child(medicationHistoryComment)
medication = Nokogiri::XML::Node.new "medication", @requestXMLDoc
medication['name']= 'aspirin'
medication['code']= '123456'
soaData.add_child(medication)

puts @requestXMLDoc.to_xml

puts 'Success!'


