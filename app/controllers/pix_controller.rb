#require 'soap/wsdlDriver'
require 'pusher'
require 'coderay'
require 'nokogiri'

class PixController < ApplicationController

  def lookup
    p "pix lookup"
    @patients = User.all

#   client = Savon.client(wsdl: "http://web03:8080/axis2/services/OrderService?wsdl" )
#    
#    puts "available ops: "
#    client.operations.each do |ops|
#      puts ops
#    end
#    puts " ~~~~ "
#result = client.get();
    respond_to do |format|
      format.xml { render :xml => @patients }
      format.json { render :json => @patients }
    end
  end

  #
  # /pix/rurl - (r)uby curl
  # @return
  # @param
  #
  #require 'REXML/document'

  def rurl
    requestBodyXML = request.body.read;
    logger.debug 'Hello PixController!!'
    Pusher.url = ENV["PUSHER_URL"]

    @requestXMLDoc = Nokogiri::XML(requestBodyXML)
    patientId = @requestXMLDoc.xpath('//fihr:reference', 'fihr' => 'http://hl7.org/fhir').first['value']
    requestedEdipi = @requestXMLDoc.xpath('//fihr:reference', 'fihr' => 'http://hl7.org/fhir').first['value']

    filename = "PIXHealthShareRequestSoapEnv.xml"
    filename = File.join(Rails.root, 'app', 'controllers', filename)
    fileXML = File.read(filename)
    @pixRequestXMLDoc = Nokogiri::XML(fileXML)

    @soapBody = @pixRequestXMLDoc.at_xpath('//soap:Body', 'soap' => 'http://www.w3.org/2003/05/soap-envelope')    
      parsedBodyXml = Nokogiri::XML::Document.parse(@soapBody.to_xml);
      parsedBodyXml.remove_namespaces!

      edipiValue = Nokogiri::XML::Node.new "value", parsedBodyXml
      edipiValue['root'] = "2.16.840.1.113883.3.42.10001.100001.12"
      edipiValue['extension'] = patientId

    @updatedPixRequest = @pixRequestXMLDoc.to_s.sub( "<!-- Placeholder for our edipi request values -->", edipiValue.to_s )
    logger.debug("add edipiValue to pix request --> " + @updatedPixRequest)

#  TODO munge the soap request xml to use the patient id and or firstname, last name from above
    begin
      orderNdcFromRtopReference = @requestXMLDoc.xpath('//fhir:reference', 'fhir' => 'http://hl7.org/fhir').last['value']

      if (orderNdcFromRtopReference.nil? || orderNdcFromRtopReference.empty?)
          exceptionMessage = 'Invalid or empty NDC code submitted - /rtop2/soaData/medication or <Order><reference value="NDC_CODE_GOES HERE"/> '
          logger.debug exceptionMessage
          raise Exception,exceptionMessage
      end

      #qbase
      #wsdl = "http://172.16.12.82:37080/axis2/services/pixmgr?wsdl"
      #endpoint = "http://172.16.12.82:37080/axis2/services/pixmgr"
      
      #itec
      wsdl = "http://10.255.166.18:37080/axis2/services/pixmgr?wsdl"
      endpoint = "http://10.255.166.18:37080/axis2/services/pixmgr"
      
      content_type = 'application/soap+xml;charset=UTF-8;action="urn:hl7-org:v3:PRPA_IN201309UV02"'
      client = Savon.client(wsdl: wsdl,
                            endpoint: endpoint,
                            headers: {
                                'Content-Type' => content_type,
                                'SOAPAction' => '""' # http://stackoverflow.com/questions/8524317/how-to-remove-soapaction-http-header-from-savon-request/8530848#8530848
                                # http://fagiani.github.io/savon/
                            },
      )

      logger.debug("Making soap pix call to: "  + endpoint)
      response = client.call(:patient_registry_get_identifiers_query, xml: @updatedPixRequest)


      filename = "PixResponse.xml"
      filename = File.join(Rails.root, 'public', 'payload-files', filename)
      File.open(filename, 'w') do |f|
        f.puts response.to_xml
      end

      @responseXMLDoc = Nokogiri::XML(response.to_xml)
      @pixResponseBody = @responseXMLDoc.at_xpath('//soap:Body', 'soap' => 'http://www.w3.org/2003/05/soap-envelope')    
      parsedResponseBodyXml = Nokogiri::XML::Document.parse(@pixResponseBody.to_xml);
      parsedResponseBodyXml.remove_namespaces!      

      #
      # create the return <rtop2/> document, and add in the original FIHRRxOrder.xml
      #
      @doc = Nokogiri::XML::Document.parse("<rtop2/>")
      rtop2 = @doc.at_css "rtop2"
      order = @requestXMLDoc.at_css "Order"
      rtop2.add_child(order)

      soaData = Nokogiri::XML::Node.new "soaData", @doc
      pixComment = Nokogiri::XML::Comment.new @doc, ' PIX lookup data '
      soaData.add_child(pixComment)

      pixListOfIds = parsedResponseBodyXml.xpath('//patient/id').each do |node|
        patient = Nokogiri::XML::Node.new "patient", @doc
        patient['ien']= node['extension']
        patient['system']= node['assigningAuthorityName']
        soaData.add_child(patient)
      end


      #pixListOfIds = parsedResponseBodyXml.xpath('//patient/id/@extension').each do |patientIen|
      #  patient = Nokogiri::XML::Node.new "patient", @doc
      #  patient['ien']= patientIen
      #  patient['system']= 'CHCS1'
      #  soaData.add_child(patient)
      #end

#
# add  <soaData/> to the <rtop/>
#
      rtop2.add_child(soaData)
      filename = "PixOut.xml"
      filename = File.join(Rails.root, 'public', 'payload-files', filename)
      File.open(filename, 'w') do |f|
        f.puts rtop2.to_xml
      end

      dateTimeStampNow = DateTime.now.to_s
      dateTimeStampNowMs = DateTime.now.to_i

      coder = HTMLEntities.new
      @encodedPushMessage = coder.encode(response.to_xml)
      title = "PIX Lookup Response @ " + dateTimeStampNow 
      message = HelperUtils.buildPusherMessage("pixSection" + dateTimeStampNowMs.to_s, @encodedPushMessage, title, "pix-heading", false)

      logger.debug "push this: " + message
      Pusher['test_channel'].trigger('my_event', {
          message: message.html_safe
      })


    rescue Exception => e
      message = 'Failed - in the pix controller ' + e.message
      errorFromGlueService = Nokogiri::XML::Node.new "errorFromGlueService", @requestXMLDoc
      errorFromGlueService.content = message
      if (rtop2.nil? || rtop2.empty?)
        @doc = Nokogiri::XML::Document.parse("<rtop2/>")
        rtop2 = @doc.at_css "rtop2"
      end
      rtop2.add_child(errorFromGlueService)
      @error = message
      logger.debug @error


      title = "PIX Lookup Error @ " + DateTime.now.to_s 
      uiMessage = HelperUtils.buildPusherMessage("pixSection" + DateTime.now.to_i.to_s, @error, title, "pix-heading", true)
      Pusher['test_channel'].trigger('my_event', {
          message: uiMessage.html_safe
      })

    end

    respond_to do |format|
      format.xml { render :xml => rtop2 }
      #format.json { render :json=>@patients }
    end
  end

  def show
    p "show patients"
    @patient = Patient.find(params[:id])
  end
end
