module FhirHl7Converter
  class Hl7ToFhirConverter
    attr_reader :hl7
    attr_reader :terrminology

    def initialize(hl7)
      @hl7 = hl7
      @terrminology = Terrminology.api
    end

    def patient
      @patient ||= Fhir::Patient.new(
        text:           PatientAttributeConverter.fhir_text(@hl7),
        identifiers:    PatientAttributeConverter.fhir_identifiers(@hl7),
        names:          PatientAttributeConverter.fhir_names(@hl7),
        telecoms:       PatientAttributeConverter.fhir_telecoms(@hl7),
        gender:         PatientAttributeConverter.fhir_gender(@hl7,         @terrminology),
        birth_date:     PatientAttributeConverter.fhir_birth_date(@hl7),
        deceased:       PatientAttributeConverter.fhir_deceased(@hl7),
        addresses:      PatientAttributeConverter.fhir_addresses(@hl7),
        marital_status: PatientAttributeConverter.fhir_marital_status(@hl7, @terrminology),
        multiple_birth: PatientAttributeConverter.fhir_multiple_birth(@hl7),
        photos:         PatientAttributeConverter.fhir_photos(@hl7),
        contacts:       PatientAttributeConverter.fhir_contacts(@hl7,      @terrminology),
        animal:         PatientAttributeConverter.fhir_animal(@hl7),
        communications: PatientAttributeConverter.fhir_communications(@hl7),
        provider:       nil,
        links:          PatientAttributeConverter.fhir_links(@hl7),
        active:         true
      )
    end

    def encounter
      @encounter ||= Fhir::Encounter.new(
        text:             EncounterAttributeConverter.pv1_to_fhir_text(@hl7.pv1),
        identifiers:      EncounterAttributeConverter.pv1_to_fhir_identifiers(@hl7.pv1),
        status:           EncounterAttributeConverter.hl7_to_fhir_status(@hl7),
        encounter_class:  EncounterAttributeConverter.pv1_to_fhir_class(@hl7.pv1),
        types:            EncounterAttributeConverter.pv1_to_fhir_types(@hl7.pv1),
        subject:          patient,
        participants:     EncounterAttributeConverter.pv1_to_fhir_participants(@hl7.pv1),
        fulfills:         EncounterAttributeConverter.hl7_to_fhir_fulfills(@hl7),
        start:            nil,
        length:           EncounterAttributeConverter.pv1_to_fhir_length(@hl7.pv1),
        reason:           EncounterAttributeConverter.hl7_to_fhir_reason(@hl7),
        indication:       nil,#Fhir::Resource,
        priority:         EncounterAttributeConverter.pv2_to_fhir_priority(@hl7.pv2),
        hospitalization:  EncounterAttributeConverter.hl7_to_fhir_hospitalization(@hl7),
        locations:        EncounterAttributeConverter.hl7_to_fhir_locations(@hl7),
        service_provider: EncounterAttributeConverter.hl7_to_fhir_service_provider(@hl7),
        part_of:          nil#Fhir::Encounter
      )
    end
  end
end
