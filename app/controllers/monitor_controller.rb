class MonitorController < ApplicationController
  def watch
  	@users = User.all  
  end
end
