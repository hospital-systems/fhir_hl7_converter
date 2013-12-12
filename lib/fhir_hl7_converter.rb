require 'fhir_hl7_converter/version'
require 'terrminology'
module FhirHl7Converter
  autoload :Factory,  'fhir_hl7_converter/factory'
  autoload :Hl7ToFhirConverter,  'fhir_hl7_converter/converters/hl7_to_fhir_converter'
  autoload :DataTypeConverter,   'fhir_hl7_converter/converters/data_type_converter'
end
