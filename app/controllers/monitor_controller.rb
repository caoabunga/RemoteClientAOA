class MonitorController < ApplicationController
  def watch
  	@someHtml = "<a href=\"#\">test it</a>".html_safe
  end
end
