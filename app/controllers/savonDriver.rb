#require 'soap/wsdlDriver'
require 'savon'

=begin
   module DBLogger
     def self.debug(message)
       p message  # replace with custom impl.
     end
   end

   Savon.configure do |config|
     config.logger = DBLogger
   end

   Savon.configure do |c|
     c.log = true
   end
=end

#client = Savon.client(wsdl: "http://172.16.12.82:37080/axis2/services/xdsbridge?wsdl" )

#filename = 'PRPA_IN201309UV02.xml'
filename = "PIXSoapEnv.xml"
file_content = File.read(filename)
@xmldoc = Nokogiri::XML(file_content)

wsdl = "http://172.16.12.82:37080/axis2/services/pixmgr?wsdl"
endpoint = "http://172.16.12.82:37080/axis2/services/pixmgr"
content_type = '"application/soap+xml;charset=UTF-8;action="urn:hl7-org:v3:PRPA_IN201309UV02"'
#namespace = "http://serviceimpl.pixpdqv3.services.hieos.vangent.com"
=begin
   wsdl = "http://172.16.12.82:37080/axis2/services/pixmgr?wsdl"

   namespaces = {
       "xmlns:soap" => "http://www.w3.org/2003/05/soap-envelope",
       "xmlns:ser" => "http://serviceimpl.pixpdq.services.hieos.vangent.com",
   }

   soap_header ={
       "wsa:Action" => "urn:hl7-org:v3:PRPA_IN201309UV02",
       }

   client = Savon.client(wsdl: wsdl,
                         namespaces: namespaces,
                         soap_header: soap_header,
                         pretty_print_xml: true

   )
=end
client = Savon.client(wsdl: wsdl,
                      endpoint: endpoint,
                      headers: {
                          'Content-Type' => content_type
                      },
)
puts "available ops: "
client.operations.each do |ops|
  puts ops
end
puts " ------------------------ "

#someXML = @xmldoc.to_s
#puts someXML
#response = client.call(:patient_registry_get_identifiers_query, message: { id: 42 })
response = client.call(:patient_registry_get_identifiers_query, xml: @xmldoc.to_s)

=begin
      response = client.call(:patient_registry_get_identifiers_query) do
        message username: "luke", password: "secret"
      end

      pp response.body.to_hash
=end


#rescue Savon::SOAP::Fault => error
#print error
#end
=begin
   response = client.request(:mes, "login") do
     soap.body = {
         "mes:Username" => "test",
         "mes:Password" => "test",
         "mes:ImpersonationUsername"=>"Test",
         "mes:ApplicationName"=>"test"
     }
   end
   pp response.to_hash
=end
