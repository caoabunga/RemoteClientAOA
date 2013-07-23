require 'net/http'
require 'uri'
require 'nokogiri'

require 'helper_utils'

class DrugController < ApplicationController
  def rurl
    @error = 'Success - drug interactions'
    requestBodyXML = request.body.read;
    logger.debug 'Hello DrugController!'

    @requestXMLDoc = Nokogiri::XML(requestBodyXML)

    medication = @requestXMLDoc.css('/rtop2/soaData/medication')

begin
# call patient history lookup
#
    urlString = "http://10.255.166.15:8080/drugdruginteraction/webresources/drug-interactions/ndc-drug-interactions/"+ medication[0]['code'] + ',' + medication[1]['code']
    responseBody = HelperUtils.do_get(urlString)

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
rescue Exception => e
  message = 'Failed - ' +  e.message + "  You can try the POSTMAN http://web03/drug test"
  soaData = @requestXMLDoc.at_css "soaData"
  errorFromGlueService = Nokogiri::XML::Node.new "errorFromGlueService", @requestXMLDoc
  errorFromGlueService.content = message
  soaData.add_child(errorFromGlueService)
  @error = message
  logger.debug @error
end
    respond_to do |format|
      format.xml { render :xml => @requestXMLDoc }
      #format.json { render :json=>@patients }
    end
  end


end
