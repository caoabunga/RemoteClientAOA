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
    medicationPrescriptionInFileName = "medicationPrescriptionIn.xml"


    requestBodyXML = request.body.read;
    @requestXMLDoc = Nokogiri::XML(requestBodyXML)

    logger.debug "saving payload file: " + orderInFilename
    HelperUtils.outputPayload(orderInFilename, @requestXMLDoc.to_xml)
    logger.debug "saved."

    filename = "medicationprescription-example-f001-combivent.xml"
    filename = File.join(Rails.root, 'app', 'controllers', filename)
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
        medicationComment = "ACETAMINOPHEN 325MG TAB *OTC*"
        medicationPrescriptionCommentXML = Nokogiri::XML::Comment.new @requestXMLDoc, medicationComment
        medication.add_child(medicationPrescriptionCommentXML)
        display = Nokogiri::XML::Node.new "display", @requestXMLDoc
        display['value']= "prescribed medication"
        medication.add_child(display)
        node.add_child(medication)
      end
      logger.debug "saving payload file: " + medicationPrescriptionInFileName
      HelperUtils.outputPayload(medicationPrescriptionInFileName, @medicationPrescription.to_xml)
      logger.debug "saved."
      #
      #  save a (pharmacy) order on the server and get an id back:
      #
      responseBody = HelperUtils.do_post(@MEDICATION_PRESCRIPTION_URL, @medicationPrescription.to_xml)
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

      dateTimeStampNow = DateTime.now.to_s
      dateTimeStampNowMs = DateTime.now.to_i

      #logger.debug "order response xml : " + orderResponseXML.to_xml

      coderayMsg = CodeRay.scan(orderResponseXML.to_xml, :xml).div

      title = "FHIR Order Response @ " + dateTimeStampNow 
      message = HelperUtils.buildPusherMessage("fhirSection" + dateTimeStampNowMs.to_s, coderayMsg, title, "fhir-heading", true)

      Pusher['test_channel'].trigger('my_event', {
          message: message.html_safe
      })

    rescue Exception => e
      message = 'Failed in the order controller - making fhir rx order call? ' + e.message + e.backtrace.join("\n")
      soaData = @requestXMLDoc.at_css "soaData"
      errorFromGlueService = Nokogiri::XML::Node.new "errorFromGlueService", @requestXMLDoc
      errorFromGlueService.content = message
      soaData.add_child(errorFromGlueService)
      @error = message
      logger.debug @error

      dateTimeStampNow = DateTime.now.to_s
      dateTimeStampNowMs = DateTime.now.to_i
      title = "FHIR Order Error @ " + DateTime.now.to_s 
      uiMessage = HelperUtils.buildPusherMessage("fhirSection" + DateTime.now.to_i.to_s, @error, title, "fhir-heading", true)
      Pusher['test_channel'].trigger('my_event', {
          message: uiMessage.html_safe
      })
    end

    respond_to do |format|
      format.xml { render :xml => orderResponseXML }
      #format.json { render :json=>@patients }
    end
  end
end
