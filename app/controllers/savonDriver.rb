   #require 'soap/wsdlDriver'
   require 'savon'
   require 'pp'

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

=begin
   <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ser="http://serviceimpl.pixpdq.services.hieos.vangent.com">
   <soap:Header xmlns:wsa="http://www.w3.org/2005/08/addressing"><wsa:Action>urn:hl7-org:v3:PRPA_IN201309UV02</wsa:Action><wsa:MessageID>uuid:a2f71d32-98d7-4116-9ea3-66096aee1c21</wsa:MessageID><wsa:To>http://172.16.12.82:37080/axis2/services/pixmgr</wsa:To></soap:Header>
   <soap:Body>
=end

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
   puts "available ops: "
    client.operations.each do |ops|
      puts ops
    end
    puts " ~~~~ "

   response = client.call(:patient_registry_get_identifiers_query, message: { id: 42 })

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
