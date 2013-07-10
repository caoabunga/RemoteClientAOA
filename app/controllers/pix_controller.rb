#require 'soap/wsdlDriver'

class PixController < ApplicationController
  def lookup
    puts "on lookup for " + params[:id]
    @patients = User.all

    client = Savon.client(wsdl: "http://web03:8080/axis2/services/OrderService?wsdl" )
    
    puts "available ops: "
    client.operations.each do |ops|
      puts ops
    end
    puts " ~~~~ "
    #result = client.get();
    
    respond_to do |format|
      format.xml { render :xml=>@patients } 
      format.json { render :json=>@patients } 
    end
  end

  def show
    @patient = Patient.find(params[:id])
  end
end
