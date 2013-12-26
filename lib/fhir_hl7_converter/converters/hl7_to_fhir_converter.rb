module FhirHl7Converter
  class Hl7ToFhirConverter
    attr_reader :hl7

    def initialize(hl7)
      @hl7 = hl7
    end

    def patient
      @patient ||= Fhir::Patient.new(
        text:           PatientAttributeConverter.fhir_text(@hl7),
        identifier:    PatientAttributeConverter.fhir_identifiers(@hl7),
        name:          PatientAttributeConverter.fhir_names(@hl7),
        telecom:       PatientAttributeConverter.fhir_telecoms(@hl7),
        gender:         PatientAttributeConverter.fhir_gender(@hl7),
        birth_date:     PatientAttributeConverter.fhir_birth_date(@hl7),
        deceased:       PatientAttributeConverter.fhir_deceased(@hl7),
        address:      PatientAttributeConverter.fhir_addresses(@hl7),
        marital_status: PatientAttributeConverter.fhir_marital_status(@hl7),
        multiple_birth: PatientAttributeConverter.fhir_multiple_birth(@hl7),
        photo:         PatientAttributeConverter.fhir_photos(@hl7),
        contact:       PatientAttributeConverter.fhir_contacts(@hl7),
        animal:         PatientAttributeConverter.fhir_animal(@hl7),
        communication: PatientAttributeConverter.fhir_communications(@hl7),
        care_provider:       nil,
        link:          PatientAttributeConverter.fhir_links(@hl7),
        active:         true
      )
    end

    def encounter
      @encounter ||= Fhir::Encounter.new(
        text:             EncounterAttributeConverter.fhir_text(@hl7),
        identifier:      EncounterAttributeConverter.fhir_identifiers(@hl7),
        status:           EncounterAttributeConverter.fhir_status(@hl7),
        encounter_class:  EncounterAttributeConverter.fhir_class(@hl7),
        type:            EncounterAttributeConverter.fhir_types(@hl7),
        subject:          patient,
        participant:     EncounterAttributeConverter.fhir_participants(@hl7),
        #TODO: откуда взялся fulfills?
        #TODO: почему start вместо period?
        period: nil,
        length:           EncounterAttributeConverter.fhir_length(@hl7),
        reason:           EncounterAttributeConverter.fhir_reason(@hl7),
        indication:       nil,#Fhir::Resource,
        priority:         EncounterAttributeConverter.fhir_priority(@hl7),
        hospitalization:  EncounterAttributeConverter.fhir_hospitalization(@hl7),
        location:        EncounterAttributeConverter.fhir_locations(@hl7),
        service_provider: EncounterAttributeConverter.fhir_service_provider(@hl7),
        part_of:          nil#Fhir::Encounter
      )
    end
  end
end
