class Patient < ActiveRecord::Base
  attr_accessible :pix_id, :name, :email
end