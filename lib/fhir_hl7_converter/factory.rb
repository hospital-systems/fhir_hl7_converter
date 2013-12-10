module FhirHl7Converter
  class Factory
    def self.hl7_to_fhir(hl7)
      FhirHl7Converter::Hl7ToFhirConverter.new(hl7)
    end
  end
end
