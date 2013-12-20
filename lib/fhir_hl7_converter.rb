require 'fhir_hl7_converter/version'
module FhirHl7Converter
  autoload :Factory,                   'fhir_hl7_converter/factory'
  autoload :Hl7ToFhirConverter,        'fhir_hl7_converter/converters/hl7_to_fhir_converter'
  autoload :DataTypeConverter,         'fhir_hl7_converter/converters/data_type_converter'
  autoload :PatientAttributeConverter, 'fhir_hl7_converter/converters/patient_attribute_converter'
  autoload :EncounterAttributeConverter, 'fhir_hl7_converter/converters/encounter_attribute_converter'
end
