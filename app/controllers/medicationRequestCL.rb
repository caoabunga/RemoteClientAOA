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
patient = @requestXMLDoc.css('/rtop2/soaData/patient')

=begin
puts patient[0]['ien'].to_s
puts patient[0]['system'].to_s
puts patient[1]['ien'].to_s
puts patient[1]['system'].to_s
=end

#
# assemble medication input xml
#
=begin
filename = "medicationInput.xml"
fileXML = File.read(filename)
@medicationXMLDoc = Nokogiri::XML(fileXML)
=end
medicationBuilder = Nokogiri::XML::Builder.new do |xml|
  xml.Patient {
    xml.ids {
      xml.id patient[0]['ien'].to_s
      xml.system patient[0]['system'].to_s
    }
    xml.ids {
      xml.id patient[1]['ien'].to_s
      xml.system patient[1]['system'].to_s
    }
  }
end

#
# call patient history lookup
#
url = URI.parse('http://10.255.166.15:8080/patienthistory/webresources/patient-history-lookup/multiple')
request = Net::HTTP::Post.new(url.path)
request.content_type = 'application/xml'
#request.body = @medicationXMLDoc.to_s
request.body = medicationBuilder.to_xml
response = Net::HTTP.start(url.host, url.port) { |http| http.request(request) }
cleanResponse = response.body.to_s[1..-1].chomp(']')
p cleanResponse

=begin
filename = "medicationResponse.xml"
fileXML = File.read(filename)
cleanResponse = Nokogiri::XML(fileXML)
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


