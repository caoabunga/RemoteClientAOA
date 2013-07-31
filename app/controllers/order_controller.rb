require 'net/http'
require 'uri'
require 'nokogiri'
require 'pusher'
require 'helper_utils'
require 'coderay'

@error = 'Success!'


class OrderController < ApplicationController

  def rurl
    @error = 'Success - order medication prescription'
    @MEDICATION_PRESCRIPTION_URL = ENV["MEDICATION_PRESCRIPTION_URL"]
    @ORDER_URL = ENV["FHIR_ORDER_URL"]
    Pusher.url = ENV["PUSHER_URL"]
    orderOutFilename = "OrderOut.xml"
    orderInFilename = "OrderIn.xml"

    requestBodyXML = request.body.read;
    @requestXMLDoc = Nokogiri::XML(requestBodyXML)

      logger.debug "saving payload file: " + orderInFilename
      HelperUtils.outputPayload(orderInFilename, @requestXMLDoc.to_xml)
      logger.debug "saved."

    filename = "medicationprescription-example-f001-combivent.xml"
    filename = File.join(Rails.root, 'app','controllers', filename)
    fileXML = File.read(filename)
    @medicationPrescription = Nokogiri::XML(fileXML)

begin
#
#  save a (pharmacy) order on the server and get an id back:
#
      responseBody = HelperUtils.do_post( @MEDICATION_PRESCRIPTION_URL, @medicationPrescription.to_xml)
#  puts responseBody
# medicationPresciptionId = '797427773'
      medicationPresciptionId = responseBody

#
# place medication prescription into order
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
      
      logger.debug "saving payload file: " + orderOutFilename
      HelperUtils.outputPayload(orderOutFilename, @requestXMLDoc.to_xml)
      logger.debug "saved."

rescue  Exception => e
  message = 'Failed making fhir rx order call:' +  e.message
  soaData = @requestXMLDoc.at_css "soaData"
  errorFromGlueService = Nokogiri::XML::Node.new "errorFromGlueService", @requestXMLDoc
  errorFromGlueService.content = message
  soaData.add_child(errorFromGlueService)
  @error = message
  logger.debug @error
end
    dateTimeStampNow = DateTime.now.to_s
    dateTimeStampNowMs = DateTime.now.to_i

    coderayMsg = CodeRay.scan( @orderResponseXML, :xml).div
    message = "<div class=\"accordion-group\">\r\n" + 
    "       <div class=\"accordion-heading fhir-heading \">\r\n" + 
    "         <a class=\"accordion-toggle\" data-toggle=\"collapse\" data-parent=\"#accordion2\" href=\"#collapse" + dateTimeStampNowMs.to_s + "\"> FHIR Order Response @ " + dateTimeStampNow + "  </a>\r\n" + 
    "       </div>\r\n" + 
    "       <div id=\"collapse" + dateTimeStampNowMs.to_s + "\" class=\"accordion-body collapse\">\r\n" + 
    "         <div class=\"accordion-inner\">\r\n" + 
            coderayMsg + 
    "         </div>\r\n" + 
    "       </div>\r\n" + 
    "     </div>"

    Pusher['test_channel'].trigger('my_event', {
      message: message.html_safe
    })     
    respond_to do |format|
      format.xml { render :xml => orderResponseXML }
      #format.json { render :json=>@patients }
    end
  end
end
