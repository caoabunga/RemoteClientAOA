require 'nokogiri'
require 'savon'

filename = "FIHRRXOrder.xml"
fileXML = File.read(filename)
@requestXMLDoc =Nokogiri::XML(fileXML)
patientId = @requestXMLDoc.css('reference').first['value']
 puts patientId

filename = "PIXRequestSoapEnv.xml"
file_content = File.read(filename)
@xmldoc = Nokogiri::XML(file_content)

#  TODO munge the soap request xml to use the patient id and or firstname, last name from above
wsdl = "http://172.16.12.82:37080/axis2/services/pixmgr?wsdl"
endpoint = "http://172.16.12.82:37080/axis2/services/pixmgr"
content_type = '"application/soap+xml;charset=UTF-8;action="urn:hl7-org:v3:PRPA_IN201309UV02"'
client = Savon.client(wsdl: wsdl,
                      endpoint: endpoint,
                      headers: {
                          'Content-Type' => content_type
                      },
)
puts "available ops: "
client.operations.each do |ops|
  puts ops
end
puts " ------------------------ "

#someXML = @xmldoc.to_s
#puts someXML
#response = client.call(:patient_registry_get_identifiers_query, message: { id: 42 })
response = client.call(:patient_registry_get_identifiers_query, xml: @xmldoc.to_s)

# TODO extract the patient and shove it back into the FIHRRxOrder.xml to form the response back to the message flow

#rescue Savon::SOAP::Fault => error
#print error
#end
