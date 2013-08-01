require 'net/http'
require 'uri'
require 'nokogiri'
require 'pusher'
require 'coderay'
require 'helper_utils'
require 'rx_helper'

class DrugController < ApplicationController

  def rurl

    @error = 'Success - drug interactions'
    @DRUG_DRUG_INTERACTION = ENV["DRUG_INTERACTION"]
    Pusher.url = ENV["PUSHER_URL"]
    drugInFilename = "DrugIn.xml"
    drugOutFilename = "DrugOut.xml"
    drugdrugInteractionOrderResponseFileName = "drugdrugInteractionOrderResponse.xml"

    logger.debug 'Hello DrugController, using: '+ @DRUG_DRUG_INTERACTION
    requestBodyXML = request.body.read;

    @requestXMLDoc = Nokogiri::XML(requestBodyXML)

    logger.debug "saving payload file: " + drugInFilename
    HelperUtils.outputPayload(drugInFilename, @requestXMLDoc.to_xml)
    logger.debug "saved."

    begin

      medication = @requestXMLDoc.css('/rtop2/soaData/medication')

      #
      # get the medication ndc from the original order as well
      #
      orderNdcFromRtopReference = @requestXMLDoc.xpath('//fihr:reference', 'fihr' => 'http://hl7.org/fhir').last['value']

      if (medication.nil? || medication.empty? || orderNdcFromRtopReference.nil? || orderNdcFromRtopReference.empty?)
          exceptionMessage = 'DrugController - NDC codes are null - /rtop2/soaData/medication or <Order><reference value="NDC_CODE_GOES HERE"/> '
          logger.debug exceptionMessage
          raise Exception,exceptionMessage
      end

      # call patient history lookup
      #

      csvNdcCode = orderNdcFromRtopReference + ","

      medication.each do |m|
        csvNdcCode = csvNdcCode + m['code']
        if m != medication.last
          csvNdcCode = csvNdcCode + ","
        end
      end

      urlString = @DRUG_DRUG_INTERACTION + csvNdcCode
      logger.debug("sending drug interaction request with: " + urlString)
      responseBody = HelperUtils.do_get(urlString)
      logger.debug("our response back is " + responseBody)

      cleanResponse = responseBody.to_s.chomp(']')
      #
      # insert drug warning  into the RTOP2_FIHRRxOrder.xml to form the response back to the message flow
      #

      soaData = @requestXMLDoc.at_css "soaData"
      medicationPrescriptionComment = Nokogiri::XML::Comment.new @requestXMLDoc, ' Medication history from ' + urlString
      soaData.add_child(medicationPrescriptionComment)
      drugDrugInteraction = Nokogiri::XML::Node.new "drugDrugInteraction", @requestXMLDoc
      drugDrugInteraction.content= cleanResponse
      soaData.add_child(drugDrugInteraction)

      logger.debug "saving payload file: " + drugOutFilename
      HelperUtils.outputPayload(drugOutFilename, @requestXMLDoc.to_xml)
      logger.debug "saved."

      messageXML = @requestXMLDoc
      #
      # Push failure to /monitoring
      #
      if (cleanResponse != "No Interactions Found")
        filename = File.join(Rails.root, 'app', 'controllers', drugdrugInteractionOrderResponseFileName)
        fileXML = File.read(filename)
        @drugDrugInteractionResponseXMLDoc = Nokogiri::XML(fileXML)
        # remove any existing medication
        @drugDrugInteractionResponseXMLDoc.xpath('//fihr:description', 'fihr' => 'http://hl7.org/fhir').remove()

        # poor man's replace
        @drugDrugInteractionResponseXMLDoc.xpath('//fihr:OrderResponse', 'fihr' => 'http://hl7.org/fhir').each do |node|
          description = Nokogiri::XML::Node.new "description", @drugDrugInteractionResponseXMLDoc
          description['value'] = "http://10.255.201.57:1414/GetMQOutRXOrder"
          description.content = cleanResponse
          @drugDrugInteractionResponseXML = @drugDrugInteractionResponseXMLDoc.root
          @drugDrugInteractionResponseXML.add_child(description)
          #
          #  change the message being pushed to the drug interaction <OrderResponse>
          #
          messageXML = @drugDrugInteractionResponseXMLDoc
        end
      end

      dateTimeStampNow = DateTime.now.to_s
      dateTimeStampNowMs = DateTime.now.to_i

      message = "<div class=\"accordion-group\">\r\n" +
          "       <div class=\"accordion-heading drug-heading\">\r\n" +
          "         <a class=\"accordion-toggle\" data-toggle=\"collapse\" data-parent=\"#accordion\" href=\"#collapse" + dateTimeStampNowMs.to_s + "\"> Drug Interaction Response @ " + dateTimeStampNow + "  </a>\r\n" +
          "       </div>\r\n" +
          "       <div id=\"collapse" + dateTimeStampNowMs.to_s + "\" class=\"accordion-body collapse\">\r\n" +
          "         <div class=\"accordion-inner\">\r\n<textarea class=\"xml-container\">" +
          messageXML.to_xml.html_safe +
          "         </textarea></div>\r\n" +
          "       </div>\r\n" +
          "     </div>"
      logger.debug("try to send drug response to pusher: ")
      logger.debug message.html_safe
      Pusher['test_channel'].trigger('my_event', {
          message: message.html_safe
      })

    rescue Exception => e
      message = 'Failed in the drug controller call. ' + e.message + e.backtrace.join("\n")
      soaData = @requestXMLDoc.at_css "soaData"
      errorFromGlueService = Nokogiri::XML::Node.new "errorFromGlueService", @requestXMLDoc
      errorFromGlueService.content = message
      soaData.add_child(errorFromGlueService)
      @error = message
      logger.error @error
    end


    logger.debug "-- done --"
    respond_to do |format|
      format.xml { render :xml => @requestXMLDoc }
      #format.json { render :json=>@patients }
    end
  end
end

