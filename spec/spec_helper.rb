module HL7SpecHelper
  def fixture(name)
    path = File.dirname(__FILE__) + "/fixtures/#{name}.hl7"
    File.readlines(path).map(&:chomp).join("\r")
  end

  def assert_address(address, xad)
    address.use.should == xad.address_type.to_p
    address.text.should == [
        xad.street_address.try(:street_or_mailing_address),
        xad.street_address.try(:street_name),
        xad.street_address.try(:dwelling_number),
        xad.other_designation,
        xad.city,
        xad.state_or_province,
        xad.zip_or_postal_code,
        xad.country
    ].map(&:to_p).join(' ')
    address.line.should == [
        xad.street_address.try(:street_or_mailing_address),
        xad.street_address.try(:street_name),
        xad.street_address.try(:dwelling_number),
        xad.other_designation
    ].map(&:to_p)
    address.city.should == xad.city.to_p
    address.state.should == xad.state_or_province.to_p
    address.zip.should == xad.zip_or_postal_code.to_p
    address.country.should == xad.country.to_p
    #address.period.start.should == DateTime.now
    #address.period.end.should == DateTime.now
    #:address_validity_range :effective_date :expiration_date
  end
end
