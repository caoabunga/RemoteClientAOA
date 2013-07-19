require 'net/http'
require 'uri'
require 'nokogiri'

@error = 'Success!'
@MEDICATION_PRESCRIPTION_URL = 'http://web03:8080/fhirprototype/webresources/medicationprescription'
@ORDER_URL = 'http://web03:8080/fhirprototype/webresources/order'

def do_post (_urlString, post_xml)
  url = URI.parse(_urlString)
  http = Net::HTTP.new(url.host, url.port)
  http.open_timeout = 10
  http.read_timeout = 10
  # FIX ME
  #http.content_type = 'application/xml'
  #http.body = post_xml
  response = http.start do |http|
    http.request_post(url.path, post_xml)
  end
  response.body
end
#
# POST-ed FIHR Rx Order XML
#
filename = "RTOP2.xml"
fileXML = File.read(filename)
@requestXMLDoc = Nokogiri::XML(fileXML)

filename = "medicationprescription-example-f001-combivent.xml"
#filename = File.join(Rails.root, 'app','controllers', filename)
fileXML = File.read(filename)
@medicationPrescription = Nokogiri::XML(fileXML)

begin
#
#  save a (pharmacy) order on the server and get an id back:
#
  responseBody = do_post(@MEDICATION_PRESCRIPTION_URL, @medicationPrescription.to_xml)
  puts responseBody

#
# TODO pull prescription id and place into order
#

  medicationPresciptionId = '797427773'
  @requestXMLDoc.xpath('//fihr:Order', 'fihr' => 'http://hl7.org/fhir').each do |node|
    detail = Nokogiri::XML::Node.new "detail", @requestXMLDoc
    type = Nokogiri::XML::Node.new "type", @requestXMLDoc
    type['value']= 'MedicationPrescription'
    detail.add_child(type)
    reference = Nokogiri::XML::Node.new "reference", @requestXMLDoc
    reference['value']= medicationPresciptionId
    detail.add_child(reference)
    node.add_child(detail)
  end
  puts @requestXMLDoc

#
# place the order
#
  order = @requestXMLDoc.xpath('//fihr:Order', 'fihr' => 'http://hl7.org/fhir')
  responseBody = do_post(@ORDER_URL, order.to_xml)

#
# insert drug warning  into the RTOP2_FIHRRxOrder.xml to form the response back to the message flow
#

  soaData = @requestXMLDoc.at_css "soaData"
  drugHistoryComment = Nokogiri::XML::Comment.new @requestXMLDoc, ' Medication history from ' + _url
  soaData.add_child(drugHistoryComment)
  drugDrugInteraction = Nokogiri::XML::Node.new "drugDrugInteraction", @requestXMLDoc
  drugDrugInteraction.content= cleanResponse
  soaData.add_child(drugDrugInteraction)
#rescue Exception => e
#  soaData = @requestXMLDoc.at_css "soaData"
#  errorFromGlueService = Nokogiri::XML::Node.new "errorFromGlueService", @requestXMLDoc
#  errorFromGlueService.content = e.message
#  soaData.add_child(errorFromGlueService)
#  @error = 'Failed -- ' +  e.message
end

if (@error == 'Success!')
  puts @requestXMLDoc.to_xml
end

puts @error


