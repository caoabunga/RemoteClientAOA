require 'net/http'
require 'uri'
require 'nokogiri'
require 'logger'
require 'pp'

require '../helpers/helper_utils'
logger = Logger.new('ordreLog.txt')

@error = 'Success - order medication prescription'
@MEDICATION_PRESCRIPTION_URL = 'http://web03:8080/fhirprototype/webresources/medicationprescription'
@ORDER_URL = 'http://web03:8080/fhirprototype/webresources/order'

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
# munge the <MedicationPrescription/> by adding the NDC from the order
#
  #
  # get the medication ndc from the original order as well
  #
  orderNdcFromRtopReference = @requestXMLDoc.xpath('//fihr:reference', 'fihr' => 'http://hl7.org/fhir').last['value']

  # remove any existing medication
  @medicationPrescription.xpath('//fihr:medication', 'fihr' => 'http://hl7.org/fhir').remove()

  # poor man's replace
  @medicationPrescription.xpath('//fihr:MedicationPrescription', 'fihr' => 'http://hl7.org/fhir').each do |node|
    medication = Nokogiri::XML::Node.new "medication", @medicationPrescription
    type = Nokogiri::XML::Node.new "type", @requestXMLDoc
    type['value']= 'Medication'
    medication.add_child(type)
    reference = Nokogiri::XML::Node.new "reference", @requestXMLDoc
    reference['value']= orderNdcFromRtopReference
    medication.add_child(reference)
    display = Nokogiri::XML::Node.new "display", @requestXMLDoc
    display['value']= "prescribed medication"
    medication.add_child(display)
    node.add_child(medication)
  end
  p @medicationPrescription.to_xml(:indent => 4)
  return
#
#  save a (pharmacy) order on the server and get an id back:
#
  responseBody = HelperUtils.do_post(@MEDICATION_PRESCRIPTION_URL, @medicationPrescription.to_xml)
#  puts responseBody
 # medicationPresciptionId = '797427773'
  medicationPresciptionId = responseBody

#
# insert/replace medication prescription id into order
#

  # remove any exiting <detail/> nodes
  @requestXMLDoc.xpath('//fihr:detail', 'fihr' => 'http://hl7.org/fhir').remove()

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

#
# place the order
#
  order = @requestXMLDoc.xpath('//fihr:Order', 'fihr' => 'http://hl7.org/fhir')
  orderResponseBody = HelperUtils.do_post(@ORDER_URL, order.to_xml)
  @orderResponseXMLDoc = Nokogiri::XML(orderResponseBody)
  orderResponseXML = @orderResponseXMLDoc.root

#
# insert drug warning  into the RTOP2_FIHRRxOrder.xml to form the response back to the message flow
#

  soaData = @requestXMLDoc.at_css "soaData"
  medicationPrescriptionComment = Nokogiri::XML::Comment.new @requestXMLDoc, ' Medication prescription from ' + @MEDICATION_PRESCRIPTION_URL
  soaData.add_child(medicationPrescriptionComment)
  orderComment = Nokogiri::XML::Comment.new @requestXMLDoc, ' Order from ' + @ORDER_URL
  soaData.add_child(orderComment)
  @requestXMLDoc.xpath('//orderResponse').remove()
  soaData.add_child(orderResponseXML.to_xml)
rescue Exception => e
 message = 'Failed - ' +  e.message + "  You can try the POSTMAN http://web03/order test"
 soaData = @requestXMLDoc.at_css "soaData"
 errorFromGlueService = Nokogiri::XML::Node.new "errorFromGlueService", @requestXMLDoc
 errorFromGlueService.content = message
 soaData.add_child(errorFromGlueService)
 @error =  message
 logger.debug @error
 p @error
end


#puts @requestXMLDoc.to_xml



