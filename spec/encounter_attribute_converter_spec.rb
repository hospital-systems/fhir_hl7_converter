require 'spec_helper'
require 'health_seven'
require 'fhir'
require 'fhir_hl7_converter'
describe FhirHl7Converter::EncounterAttributeConverter do
  include HL7SpecHelper

  let(:subject) { FhirHl7Converter::EncounterAttributeConverter }
  let(:message) { fixture('adt_a01') }
  let(:hl7) { HealthSeven::Message.parse(message) }
  let(:gateway) { FhirHl7Converter::Factory.hl7_to_fhir(hl7) }
  let(:terrminology) { gateway.terrminology }

  example do
    subject.fhir_reason(hl7, terrminology).should == hl7.pv2.admit_reason.text.to_p
  end

  example do
    puts hl7.pv2.visit_priority_code.to_yaml
    puts subject.fhir_priority(hl7, terrminology)
  end
end
