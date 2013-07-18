#require 'soap/wsdlDriver'

class PixController < ApplicationController
  def lookup
    puts "on lookup for " + params[:id]
    @patients = User.all

#   client = Savon.client(wsdl: "http://web03:8080/axis2/services/OrderService?wsdl" )
#    
#    puts "available ops: "
#    client.operations.each do |ops|
#      puts ops
#    end
#    puts " ~~~~ "
#result = client.get();
    respond_to do |format|
      format.xml { render :xml => @patients }
      format.json { render :json => @patients }
    end
  end

  #
  # /pix/rurl - (r)uby curl
  # @return
  # @param
  #
  #require 'REXML/document'
  require 'nokogiri'

  def rurl
    requestBodyXML = request.body.read;
    logger.debug 'Hello PixController!'

    @requestXMLDoc = Nokogiri::XML(requestBodyXML)
#@requestXMLDoc.remove_namespaces!
    patientId = @requestXMLDoc.xpath('//fihr:reference', 'fihr' => 'http://hl7.org/fhir').first['value']
#puts patientId

    filename = "PIXRequestSoapEnv.xml"
filename = File.join(Rails.root, 'app','controllers', filename)
    file_content = File.read(filename)
    @pixRequestXMLDoc = Nokogiri::XML(file_content)
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
# here is an example of how to set it (remove namespace)
#
#@pixRequestXMLDoc.css('patientIdentifier value').first['root'] = '12121212'
puts @pixRequestXMLDoc

=end

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


=begin
#
# Debug
#
puts "available ops: "
client.operations.each do |ops|
  puts ops
end
puts " ------------------------ "
=end

    response = client.call(:patient_registry_get_identifiers_query, xml: @pixRequestXMLDoc.to_s)

#
# TODO extract the patient and shove it back into the FIHRRxOrder.xml to form the response back to the message flow
#

#
# create the return <rtop2/> document, and add in the original FIHRRxOrder.xml
#
    @doc = Nokogiri::XML::Document.parse("<rtop2/>")
    rtop2 = @doc.at_css "rtop2"
    order = @requestXMLDoc.at_css "Order"
    rtop2.add_child(order)

#
# create <soaData/> node and add the patient dat
#
    soaData = Nokogiri::XML::Node.new "soaData", @doc
    pixComment = Nokogiri::XML::Comment.new @doc, ' PIX lookup data '
    soaData.add_child(pixComment)

    patient = Nokogiri::XML::Node.new "patient", @doc
    patient['ien']= '123456'
    patient['system']= 'CHCS2'
    soaData.add_child(patient)

#
# add  <soaData/> to the <rtop/>
#
    rtop2.add_child(soaData)


    respond_to do |format|
      format.xml { render :xml => rtop2 }
      #format.json { render :json=>@patients }
    end
  end

  def show
    @patient = Patient.find(params[:id])
  end
end
