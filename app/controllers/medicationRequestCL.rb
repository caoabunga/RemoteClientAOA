require 'net/http'
require 'uri'
require 'nokogiri'

#
# POST-ed FIRH Rx Order XML
#
filename = "FIHRRXOrder.xml"
fileXML = File.read(filename)
@requestXMLDoc = Nokogiri::XML(fileXML)
patientId = @requestXMLDoc.css('reference').first['value']
puts patientId

#
# assemble medication input xml
# TODO use patients ids from above to do this
#
filename = "medicationInput.xml"
file_content = File.read(filename)
@medicationXMLDoc = Nokogiri::XML(file_content)

#
# call patient history lookup
#
url = URI.parse('http://10.255.166.15:8080/patienthistory/webresources/patient-history-lookup/multiple')
request = Net::HTTP::Post.new(url.path)
request.content_type = 'application/xml'
request.body = @medicationXMLDoc.to_s
response = Net::HTTP.start(url.host, url.port) { |http| http.request(request) }
puts 'response'
cleanResponse = response.body.to_s[1..-1].chomp(']')


#
# TODO extract medications
#
firstXML, *lastXML = cleanResponse.split(/, /)
puts firstXML
puts *lastXML

@firstXML = Nokogiri::XML(firstXML)

#
# insert medications into the FIHRRxOrder.xml to form the response back to the message flow
#
medication = Nokogiri::XML::Node.new "medication", @requestXMLDoc
medication['name']= 'aspirin'
medication['code']= '123456'
detail = @requestXMLDoc.at_css "soaData"
detail.add_next_sibling(medication)

puts @requestXMLDoc.to_s


