require 'net/http'
require 'uri'
require 'nokogiri'

require 'helper_utils'

class DrugController < ApplicationController
  def rurl

    @error = 'Success - drug interactions'
    @DRUG_DRUG_INTERACTION = ENV["DRUG_INTERACTION"]

    logger.debug 'Hello DrugController, using: '+ @DRUG_DRUG_INTERACTION
    requestBodyXML = request.body.read;
    
    @requestXMLDoc = Nokogiri::XML(requestBodyXML)
    filename = "DrugIn.xml"
      filename = File.join(Rails.root, 'app','controllers', 'logs', filename)
      File.open(filename, 'w') do |f|
      f.puts @requestXMLDoc.to_xml
    end
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
    filename = "DrugOut.xml"
      filename = File.join(Rails.root, 'app','controllers', 'logs', filename)
      File.open(filename, 'w') do |f|
      f.puts @requestXMLDoc.to_xml
    end
rescue Exception => e
  message = 'Failed - ' +  e + "  You can try the POSTMAN http://web03/drug test"
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
