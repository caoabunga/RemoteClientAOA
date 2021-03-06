require 'nokogiri'
require 'savon'
require 'pp'

filename = "FIHRRXOrder.xml"
fileXML = File.read(filename)
@requestXMLDoc = Nokogiri::XML(fileXML)
#@requestXMLDoc.remove_namespaces!
patientId = @requestXMLDoc.xpath('//fihr:reference', 'fihr' => 'http://hl7.org/fhir').first['value']
#puts patientId

filename = "PIXRequestSoapEnv.xml"
filename = "PIXHealthShareRequestSoapEnv.xml"
#filename = File.join(Rails.root, 'app','controllers', filename)
fileXML = File.read(filename)
@pixRequestXMLDoc = Nokogiri::XML(fileXML)
=begin
@pixRequestXMLDoc.remove_namespaces!
patientIdentifier = @pixRequestXMLDoc.css('patientIdentifier value').first['root']

# this works, but does not get me down to the attribute
patientIdentifier = @pixRequestXMLDoc.xpath('//hl7:value/@root', 'hl7' => 'urn:hl7-org:v3')
elem = @pixRequestXMLDoc.xpath('//hl7:value', 'hl7' => 'urn:hl7-org:v3')
pp elem
#puts patientIdentifier.to_xml
#puts patientIdentifier

#
# here is an example of how to set it with (remove namespace)
#
#@pixRequestXMLDoc.css('patientIdentifier value').first['root'] = '12121212'
puts @pixRequestXMLDoc

=end
begin
#
#  TODO munge the soap request xml to use the patient id and or firstname, last name from above
#
	wsdl = "http://172.16.12.82:37080/axis2/services/pixmgr?wsdl"
	endpoint = "http://172.16.12.82:37080/axis2/services/pixmgr"
	wsdl = "http://web03/IHE/PIXManager.wsdl"
	#wsdl="http://www.sandiegoimmunizationregistry.org/PIXManager?wsdl"
	endpoint = "http://10.255.166.17:57772/csp/public/hsbus/HS.IHE.PIXv3.Manager.Services.cls"
	content_type = 'application/soap+xml;charset=UTF-8;action="urn:hl7-org:v3:PRPA_IN201309UV02"'
	client = Savon.client(wsdl: wsdl,
	                      endpoint: endpoint,
	                      headers: {
	                          'Content-Type' => content_type,
	                          'SOAPAction' => '""' # http://stackoverflow.com/questions/8524317/how-to-remove-soapaction-http-header-from-savon-request/8530848#8530848
	                                               # http://fagiani.github.io/savon/
	                      },
	)

=begin
#
# Debug
#

puts "available ops: "
client.operations.each do |ops|
  puts ops
end
puts " ------------------------ "
puts @pixRequestXMLDoc.to_s
=end

	response = client.call(:patient_registry_get_identifiers_query, xml: @pixRequestXMLDoc.to_s)
	#puts response.xpath('//fihr:patient', 'fihr' => 'urn:hl7-org:v3')
	pixXML = Nokogiri::XML::Document.parse(response.to_xml);
	pixXML.remove_namespaces!
	pixListOfIds = pixXML.xpath('//patient/id/@extension')


#
# TODO extract the patient and shove it back into the FIHRRxOrder.xml to form the response back to the message flow
#

#
# create the return <rtop2/> document, and add in the original FIHRRxOrder.xml
#
	@doc = Nokogiri::XML::Document.parse("<rtop2/>")
	rtop2 =  @doc.at_css "rtop2"
	order = @requestXMLDoc.at_css "Order"
	rtop2.add_child(order)

	#
	# create <soaData/> node and add the patient dat
	#
	soaData = Nokogiri::XML::Node.new "soaData", @doc
	pixComment = Nokogiri::XML::Comment.new @doc, ' PIX lookup data '
	soaData.add_child(pixComment)

   	patient = Nokogiri::XML::Node.new "patient", @doc
	patient['ien']= '101'
	patient['system']= 'CHCS1'
	soaData.add_child(patient)
	patient = Nokogiri::XML::Node.new "patient", @doc
    patient['ien']= '7988'
    patient['system']= 'CHCS2'
	soaData.add_child(patient)

#
# add  <soaData/> to the <rtop/>
#
	rtop2.add_child(soaData)

rescue  Exception => e
  @doc = Nokogiri::XML::Document.parse("<rtop2/>")
  rtop2 =  @doc.at_css "rtop2"
  message = 'Failed - ' +  e.message + " You can try the POSTMAN http://web03/medication test" 
  #soaData = @requestXMLDoc.at_css "soaData"
  errorFromGlueService = Nokogiri::XML::Node.new "errorFromGlueService", @requestXMLDoc
  errorFromGlueService.content = message
  rtop2.add_child(errorFromGlueService)
  @error = message 
  #logger.debug @error
  puts @error
end

#
# debug
#
#puts rtop2.to_xml

