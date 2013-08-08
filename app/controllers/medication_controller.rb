require 'net/http'
require 'uri'
require 'nokogiri'
require 'figaro'
require 'pusher'
require 'coderay'

class MedicationController < ApplicationController

  def rurl
    @PATIENT_HISTORY_URL = ENV["ITEC_PATIENT_HISTORY_URL"]
    Pusher.url = ENV["PUSHER_URL"]
    medInFilename = "MedicationIn.xml"
    medOutFilename = "MedicationOut.xml"

    logger.debug "Using Patient History URL: " + @PATIENT_HISTORY_URL

    @error = "Success - patient history lookup"
    requestBodyXML = request.body.read;

    @requestXMLDoc = Nokogiri::XML(requestBodyXML)
    patient = @requestXMLDoc.css('/rtop2/soaData/patient')

    logger.debug "saving payload file: " + medInFilename
    HelperUtils.outputPayload(medInFilename, @requestXMLDoc.to_xml)
    logger.debug "saved."

    #
    # assemble medication input xml
    #


    medicationBuilder = Nokogiri::XML::Builder.new do |xml|
      xml.Patient {
          patient.each do |p|
            xml.ids {
              xml.id p['ien']
              xml.system p['system']
            }
          end
      }
    end

    p "Posting medication history -->"
    #p medicationBuilder.to_xml

    begin
      #
      # call patient history lookup
      #
      url = URI.parse(@PATIENT_HISTORY_URL)
      request = Net::HTTP::Post.new(url.path)
      request.content_type = 'application/xml'

      request.body = medicationBuilder.to_xml
      puts  'our request body: ' + request.body
      response = Net::HTTP.start(url.host, url.port) { |http| http.request(request) }
      
      cleanResponse = response.body.to_s[1..-1].chomp(']')
      puts 'response ---------' + cleanResponse

      firstXML, *lastXML = cleanResponse.split(/, /)
      #puts firstXML
      #puts *lastXML
      @lastXML = Nokogiri::XML(*lastXML)
      @lastXML.remove_namespaces!
      #logger.debug "lastXML --> " + @lastXML.to_s

      @firstXML = Nokogiri::XML(firstXML)
      @firstXML.remove_namespaces!
      #logger.debug "firstXML --> " + firstXML.to_s

      build = Nokogiri::XML::Builder.new do |xml|
        xml.root {
          xml.list @lastXML
          xml.list @firstXML
        }
      end
      logger.debug "BAM --> " + build.to_xml

      #
      # insert medications into the FIHRRxOrder.xml to form the response back to the message flow
      #

      soaData = @requestXMLDoc.at_css "soaData"
      medicationHistoryComment = Nokogiri::XML::Comment.new @requestXMLDoc, @PATIENT_HISTORY_URL
      soaData.add_child(medicationHistoryComment)


      @ndcCodes = @firstXML.xpath("//display")
      @ndcCodes.each do |code|
        medication = Nokogiri::XML::Node.new "medication", @requestXMLDoc
        #medication['name']= 'aspirin'
        medication['code']= code['value']
        #logger.debug "first set --> " + code['value']
        soaData.add_child(medication)
      end


      @lastSetNdcCodes = @lastXML.xpath("//display")
      @lastSetNdcCodes.each do |code|
        medication = Nokogiri::XML::Node.new "medication", @requestXMLDoc
        #medication['name']= 'aspirin'
        medication['code']= code['value']
        #logger.debug "second set --> " + code['value']
        soaData.add_child(medication)
      end



      logger.debug "saving payload file: " + medOutFilename
      HelperUtils.outputPayload(medOutFilename, @requestXMLDoc.to_xml)
      logger.debug "saved."


      #coderayMsg = CodeRay.scan(soaData.to_s, :html).div
      dateTimeStampNow = DateTime.now.to_s
      dateTimeStampNowMs = DateTime.now.to_i

      title = "Medication History Lookup Response @ " + dateTimeStampNow 
      message = HelperUtils.buildPusherMessage("medSection" + dateTimeStampNowMs.to_s, soaData.to_xml, title, "med-heading", false)

      logger.debug message.html_safe
      logger.debug "try to send to pusher now"
      Pusher['test_channel'].trigger('my_event', {
          message: message.html_safe
      })

    rescue Exception => e
      message = 'Failed in medication controller making patient history call? ' + e.message + e.backtrace.join("\n")
      #soaData = @requestXMLDoc.at_css "soaData"
      #errorFromGlueService = Nokogiri::XML::Node.new "errorFromGlueService", @requestXMLDoc
      #errorFromGlueService.content = message
      #soaData.add_child(errorFromGlueService)
      @error = message
      logger.debug @error

      title = "Patient History Lookup Error @ " + DateTime.now.to_s 
      uiMessage = HelperUtils.buildPusherMessage("medSection" + DateTime.now.to_i.to_s, @error, title, "med-heading" , true)
      Pusher['test_channel'].trigger('my_event', {
          message: uiMessage.html_safe
      })

    end

    logger.debug "----"
    respond_to do |format|
      format.xml { render :xml => @requestXMLDoc }
      #format.json { render :json=>@patients }
    end
  end
end