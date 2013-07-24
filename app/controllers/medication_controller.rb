require 'net/http'
require 'uri'
require 'nokogiri'

class MedicationController < ApplicationController
  def rurl
    @PATIENT_HISTORY_URL = 'http://10.255.166.15:8080/patienthistory/webresources/patient-history-lookup/multiple'
    @error = "Success - patient history lookup"
    requestBodyXML = request.body.read;
    logger.debug 'Hello MedicationController!'

    @requestXMLDoc = Nokogiri::XML(requestBodyXML)
    patient = @requestXMLDoc.css('/rtop2/soaData/patient')


    filename = "MedicationIn.xml"
    filename = File.join(Rails.root, 'app','controllers', 'logs', filename)
    File.open(filename, 'w') do |f|
      f.puts @requestXMLDoc.to_xml
    end


#
# assemble medication input xml
#

    medicationBuilder = Nokogiri::XML::Builder.new do |xml|
      xml.Patient {
        xml.ids {
          xml.id patient[0]['ien'].to_s
          xml.system patient[0]['system'].to_s
        }
        #xml.ids {
        #  xml.id patient[1]['ien'].to_s
        #  xml.system patient[1]['system'].to_s
        #}

      }
    end
    begin
    #
    # call patient history lookup
    #
        url = URI.parse(@PATIENT_HISTORY_URL)
        request = Net::HTTP::Post.new(url.path)
        request.content_type = 'application/xml'

        request.body = medicationBuilder.to_xml
        response = Net::HTTP.start(url.host, url.port) { |http| http.request(request) }
        puts 'response ---------'
        cleanResponse = response.body.to_s[1..-1].chomp(']')


    #
    # TODO extract medications
    #
        firstXML, *lastXML = cleanResponse.split(/, /)
        puts firstXML
        puts *lastXML

        @firstXML = Nokogiri::XML(firstXML)
        @firstXML.remove_namespaces!

    #
    # insert medications into the FIHRRxOrder.xml to form the response back to the message flow
    #

    soaData = @requestXMLDoc.at_css "soaData"
    medicationHistoryComment = Nokogiri::XML::Comment.new @requestXMLDoc, @PATIENT_HISTORY_URL
    soaData.add_child(medicationHistoryComment)
    medication = Nokogiri::XML::Node.new "medication", @requestXMLDoc
    medication['name']= 'aspirin'
    medication['code']= '57344010901'
    soaData.add_child(medication)
    medication = Nokogiri::XML::Node.new "medication", @requestXMLDoc
    medication['name']= 'tylenol'
    medication['code']= '52125030402'
    soaData.add_child(medication)

    filename = "MedicationOut.xml"
    filename = File.join(Rails.root, 'app','controllers', 'logs', filename)
    File.open(filename, 'w') do |f|
      f.puts @requestXMLDoc.to_xml
    end
    
    logger.debug @error

    rescue  Exception => e
      message = 'Failed - ' +  e.message + ".  You can try the POSTMAN http://web03/medication test." 
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
