#require 'soap/wsdlDriver'

class FhirorderController < ApplicationController
  def create
    puts "on fhir order post " 
    doc = Nokogiri::XML(request.body.read) # or Nokogiri::XML.fragment
    puts doc
    puts doc.css('date').first['value']
    @patients = User.all
	respond_to do |format|
      format.xml { render :xml=>@patients } 
      format.json { render :json=>@patients } 
    end
  end
end
