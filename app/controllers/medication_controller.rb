require 'net/http'
require 'uri'
require 'nokogiri'

class MedicationController < ApplicationController
  def rurl
    requestBodyXML = request.body.read;
    logger.debug 'Hello MedicationController!'

    @requestXMLDoc = Nokogiri::XML(requestBodyXML)
    patient = @requestXMLDoc.css('/rtop2/soaData/patient')


#
# assemble medication input xml
#

    medicationBuilder = Nokogiri::XML::Builder.new do |xml|
      xml.Patient {
        xml.ids {
          xml.id_ patient[0]['ien'].to_s
          xml.system patient[0]['system'].to_s
        }
        #xml.ids {
        #  xml.id_ patient[1]['ien'].to_s
        #  xml.system patient[1]['system'].to_s
        #}

      }
    end

#
# call patient history lookup
#
    url = URI.parse('http://10.255.166.15:8080/patienthistory/webresources/patient-history-lookup/multiple')
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
    medicationHistoryComment = Nokogiri::XML::Comment.new @requestXMLDoc, ' Medication history from endpoint/patienthistory/webresources/patient-history-lookup  '
    soaData.add_child(medicationHistoryComment)
    medication = Nokogiri::XML::Node.new "medication", @requestXMLDoc
    medication['name']= 'aspirin'
    medication['code']= '123456'
    soaData.add_child(medication)

    respond_to do |format|
      format.xml { render :xml => @requestXMLDoc }
      #format.json { render :json=>@patients }
    end
  end


end
