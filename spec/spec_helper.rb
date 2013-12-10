module HL7SpecHelper
  def fixture(name)
    path = File.dirname(__FILE__) + "/fixtures/#{name}.hl7"
    File.readlines(path).map(&:chomp).join("\r")
  end
end
