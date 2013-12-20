module FhirHl7Converter
  class Hl7ToFhirConverter
    attr_reader :hl7

    def initialize(hl7)
      @hl7 = hl7
    end

    def patient
      @patient ||= Fhir::Patient.new(
        text:           PatientAttributeConverter.fhir_text(@hl7),
        identifiers:    PatientAttributeConverter.fhir_identifiers(@hl7),
        names:          PatientAttributeConverter.fhir_names(@hl7),
        telecoms:       PatientAttributeConverter.fhir_telecoms(@hl7),
        gender:         PatientAttributeConverter.fhir_gender(@hl7),
        birth_date:     PatientAttributeConverter.fhir_birth_date(@hl7),
        deceased:       PatientAttributeConverter.fhir_deceased(@hl7),
        addresses:      PatientAttributeConverter.fhir_addresses(@hl7),
        marital_status: PatientAttributeConverter.fhir_marital_status(@hl7),
        multiple_birth: PatientAttributeConverter.fhir_multiple_birth(@hl7),
        photos:         PatientAttributeConverter.fhir_photos(@hl7),
        contacts:       PatientAttributeConverter.fhir_contacts(@hl7),
        animal:         PatientAttributeConverter.fhir_animal(@hl7),
        communications: PatientAttributeConverter.fhir_communications(@hl7),
        provider:       nil,
        links:          PatientAttributeConverter.fhir_links(@hl7),
        active:         true
      )
    end

    def encounter
      @encounter ||= Fhir::Encounter.new(
        text:             EncounterAttributeConverter.fhir_text(@hl7),
        identifiers:      EncounterAttributeConverter.fhir_identifiers(@hl7),
        status:           EncounterAttributeConverter.fhir_status(@hl7),
        encounter_class:  EncounterAttributeConverter.fhir_class(@hl7),
        types:            EncounterAttributeConverter.fhir_types(@hl7),
        subject:          patient,
        participants:     EncounterAttributeConverter.fhir_participants(@hl7),
        #TODO: откуда взялся fulfills?
        fulfills:         EncounterAttributeConverter.fhir_fulfills(@hl7),
        #TODO: почему start вместо period?
        start:            nil,
        length:           EncounterAttributeConverter.fhir_length(@hl7),
        reason:           EncounterAttributeConverter.fhir_reason(@hl7),
        indication:       nil,#Fhir::Resource,
        priority:         EncounterAttributeConverter.fhir_priority(@hl7),
        hospitalization:  EncounterAttributeConverter.fhir_hospitalization(@hl7),
        locations:        EncounterAttributeConverter.fhir_locations(@hl7),
        service_provider: EncounterAttributeConverter.fhir_service_provider(@hl7),
        part_of:          nil#Fhir::Encounter
      )
    end
  end
end
