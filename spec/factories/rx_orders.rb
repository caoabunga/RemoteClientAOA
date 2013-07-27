# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :rx_order do
    fhirorder "MyString"
    status "MyString"
  end
end
