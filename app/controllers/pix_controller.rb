#require 'soap/wsdlDriver'

class PixController < ApplicationController
  def lookup
    puts "on lookup for " + params[:id]
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
      format.xml { render :xml=>@patients } 
      format.json { render :json=>@patients } 
    end
  end
  #
  # /pix/rurl - (r)uby curl
  # @return
  # @param
  #
  #require 'REXML/document'
  require 'nokogiri'

  def rurl
    retXML = request.body.read;
    logger.debug 'Hello world!'
    #logger.debug request.body.read
    #@patients = User.all
    # extract event information
    doc = REXML::Document.new(retXML)
    patientIds = []
    links = []
    doc.elements.each('/Order/subject/reference') do |ele|
      patientIds << ele
    end
    @doc =Nokogiri::XML(retXML)
    #logger.debug @doc.to_s
    #logger.debug @doc.xpath('/Order')     # doesn't work
    logger.debug @doc.css('reference').first['value']
    logger.debug patientIds

    respond_to do |format|
      format.xml { render :xml=>retXML}
      #format.json { render :json=>@patients }
    end
  end

  def show
    @patient = Patient.find(params[:id])
  end
end
