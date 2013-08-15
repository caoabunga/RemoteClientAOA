require '../helpers/helper_utils'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'logger'


logger = Logger.new(STDOUT)

@PATIENT_LIST_URL = 'http://10.255.166.15:9080/legacy-hdata-service/patient/list?system=chcs&framework=jdbc'
@error = "Success"

def getPatientList ( patientURL)
#
# call patient history lookup
#
  responseBody = HelperUtils.do_get(patientURL)
  p responseBody.to_s

end



begin

getPatientList(@PATIENT_LIST_URL)

=begin
rescue  Exception => e
  message = 'Failed - ' +  e.message 
  logger.debug @error
=end


end



