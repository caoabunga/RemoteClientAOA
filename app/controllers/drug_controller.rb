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

    logger.debug 'Hello DrugController, using: '+ @DRUG_DRUG_INTERACTION
    requestBodyXML = request.body.read;
    
    @requestXMLDoc = Nokogiri::XML(requestBodyXML)
    
    logger.debug "saving payload file: " + drugInFilename 
    HelperUtils.outputPayload(drugInFilename, @requestXMLDoc.to_xml)
    logger.debug "saved."

    medication = @requestXMLDoc.css('/rtop2/soaData/medication')

    begin
    # call patient history lookup
    #
        csvNdcCode = ""
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

        cleanResponse = responseBody.to_s[1..-1].chomp(']')
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

    rescue Exception => e
      message = 'Failed making patient history call: ' +  e
      soaData = @requestXMLDoc.at_css "soaData"
      errorFromGlueService = Nokogiri::XML::Node.new "errorFromGlueService", @requestXMLDoc
      errorFromGlueService.content = message
      soaData.add_child(errorFromGlueService)
      @error = message
      logger.error @error
    end
    coderayMsg = CodeRay.scan( @requestXMLDoc.to_xml, :xml).div
    message =  "<label for=\"xml-container\">Drug Interaction Response:</label>" + coderayMsg
    Pusher['test_channel'].trigger('my_event', {
      message: message
    })
    respond_to do |format|
      format.xml { render :xml => @requestXMLDoc }
      #format.json { render :json=>@patients }
    end
  end


end
