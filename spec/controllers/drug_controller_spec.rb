require 'spec_helper'

describe DrugController do

  describe "GET 'rurl'" do
    it "returns http success" do
      get 'rurl'
      response.should be_success
    end
  end

end
