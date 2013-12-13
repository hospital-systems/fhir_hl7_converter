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
        text:           PatientAttributeConverter.fhir_text(@hl7, @terrminology),
        identifiers:    PatientAttributeConverter.fhir_identifiers(@hl7, @terrminology),
        names:          PatientAttributeConverter.fhir_names(@hl7, @terrminology),
        telecoms:       PatientAttributeConverter.fhir_telecoms(@hl7, @terrminology),
        gender:         PatientAttributeConverter.fhir_gender(@hl7, @terrminology),
        birth_date:     PatientAttributeConverter.fhir_birth_date(@hl7, @terrminology),
        deceased:       PatientAttributeConverter.fhir_deceased(@hl7, @terrminology),
        addresses:      PatientAttributeConverter.fhir_addresses(@hl7, @terrminology),
        marital_status: PatientAttributeConverter.fhir_marital_status(@hl7, @terrminology),
        multiple_birth: PatientAttributeConverter.fhir_multiple_birth(@hl7, @terrminology),
        photos:         PatientAttributeConverter.fhir_photos(@hl7, @terrminology),
        contacts:       PatientAttributeConverter.fhir_contacts(@hl7, @terrminology),
        animal:         PatientAttributeConverter.fhir_animal(@hl7, @terrminology),
        communications: PatientAttributeConverter.fhir_communications(@hl7, @terrminology),
        provider:       nil,
        links:          PatientAttributeConverter.fhir_links(@hl7, @terrminology),
        active:         true
      )
    end

    def encounter
      @encounter ||= Fhir::Encounter.new(
        text:             EncounterAttributeConverter.pv1_to_fhir_text(@hl7, @terrminology),
        identifiers:      EncounterAttributeConverter.pv1_to_fhir_identifiers(@hl7, @terrminology),
        status:           EncounterAttributeConverter.hl7_to_fhir_status(@hl7, @terrminology),
        encounter_class:  EncounterAttributeConverter.pv1_to_fhir_class(@hl7, @terrminology),
        types:            EncounterAttributeConverter.pv1_to_fhir_types(@hl7, @terrminology),
        subject:          patient,
        participants:     EncounterAttributeConverter.pv1_to_fhir_participants(@hl7, @terrminology),
        fulfills:         EncounterAttributeConverter.hl7_to_fhir_fulfills(@hl7, @terrminology),
        start:            nil,
        length:           EncounterAttributeConverter.pv1_to_fhir_length(@hl7, @terrminology),
        reason:           EncounterAttributeConverter.hl7_to_fhir_reason(@hl7, @terrminology),
        indication:       nil,#Fhir::Resource,
        priority:         EncounterAttributeConverter.pv2_to_fhir_priority(@hl7, @terrminology),
        hospitalization:  EncounterAttributeConverter.hl7_to_fhir_hospitalization(@hl7, @terrminology),
        locations:        EncounterAttributeConverter.hl7_to_fhir_locations(@hl7, @terrminology),
        service_provider: EncounterAttributeConverter.hl7_to_fhir_service_provider(@hl7, @terrminology),
        part_of:          nil#Fhir::Encounter
      )
    end
  end
end
