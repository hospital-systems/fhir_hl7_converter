module FhirHl7Converter
  module EncounterAttributeConverter
    extend self

    def fhir_text(hl7, terrminology)
      hl7.pv1
      Fhir::Narrative.new(
          status: 'TODO',
          div:    'TODO'
      )
    end

    def fhir_identifiers(hl7, terrminology)
      [DataTypeConverter.cx_to_fhir_identifier(hl7.pv1.visit_number)] if hl7.pv1.visit_number
    end

    def fhir_status(hl7, terrminology)
      #Fhir::Code,No clear equivalent in V2.x; active/finished could be inferred from PV1-44, PV1-45, PV2-24; inactive could be inferred from PV2-16
    end

    def fhir_class(hl7, terrminology)
      patient_class = hl7.pv1.patient_class.try(:to_p)
      patient_class && Fhir::Code.new(patient_class)
    end

    def fhir_types(hl7, terrminology)
      admission_type = hl7.pv1.admission_type.try(:to_p)
      coding         = terrminology.coding(
        'http://hl7.org/fhir/v2/vs/0007',
        admission_type
      )
      admission_type && [
        Fhir::CodeableConcept.new(
          codings: [Fhir::Coding.new(coding)],
          text:    coding[:display] || admission_type
        )]
    end

    def fhir_participants(hl7, terrminology)
      pv1 = hl7.pv1
      pv1.attending_doctors.map{ |xcn| xcn_to_fhir_participant(xcn, 'attending') } +
        pv1.referring_doctors.map{ |xcn| xcn_to_fhir_participant(xcn, 'referrer') } +
        pv1.consulting_doctors.map{ |xcn| xcn_to_fhir_participant(xcn, 'consulting') } +
        pv1.admitting_doctors.map{ |xcn| xcn_to_fhir_participant(xcn, 'admitter') }
    end


    def xcn_to_fhir_participant(xcn, code)
      Fhir::Encounter::Participant.new(
        types: [code],
        practitioner: DataTypeConverter.xcn_to_fhir_practitioner(xcn)
      )
    end

    def fhir_fulfills(hl7, terrminology)
      nil#Fhir::Resource,SCH-1-placer appointment ID / SCH-2-filler appointment ID
    end

    def fhir_length(hl7, terrminology)
      hl7.pv1
      nil
      #Fhir::Quantity,(PV1-45 less PV1-44) iff ( (PV1-44 not empty) and (PV1-45 not empty) ); units in minutes
    end

    def fhir_reason(hl7, terrminology)
      #hl7.evn.event_reason_code.to_yaml
      #hl7.pv2.admit_reason.text.to_p
      hl7.try(:pv2).try(:admit_reason).try(:text).try(:to_p) # may be fully encoded with some terminology
    end

    def fhir_priority(hl7, terrminology)
      hl7.pv2
      nil
      #Fhir::CodeableConcept,PV2-25-visit priority code
    end

    def fhir_hospitalization(hl7, terrminology)
      Fhir::Encounter::Hospitalization.new(
        pre_admission_identifier: fhir_pre_admission_identifier(hl7, terrminology),
        origin: nil,#Fhir::Location,
        admit_source: pv1_to_admit_source(hl7.pv1, terrminology),
        period: hl7_to_fhir_period(hl7),
        accomodations: pv1_to_fhir_accomodations(hl7.pv1),
        diet: fhir_diet(hl7, terrminology),
        special_courtesies: pv1_to_fhir_special_courtesies(hl7.pv1),
        special_arrangements: pv1_to_fhir_special_arrangements(hl7),
        destination: nil,#Fhir::Location,
        discharge_disposition: pv1_to_discharge_disposition(hl7.pv1),
        re_admission: fhir_re_admission(hl7, terrminology)
      )
    end

    def fhir_pre_admission_identifier(hl7, terrminology)
      DataTypeConverter.cx_to_fhir_identifier(hl7.pv1.preadmit_number) if hl7.pv1.preadmit_number
    end

    def pv1_to_admit_source(hl7, terrminology)
      #Fhir::CodeableConcept,PV1-14-admit source
      admit_source = hl7.pv1.admit_source.try(:to_p)
      coding       = terrminology.coding(
        'http://hl7.org/fhir/vs/encounter-admit-source',
        admit_source_to_code(admit_source, terrminology)
      )
      admit_source && Fhir::CodeableConcept.new(
        codings: [Fhir::Coding.new(coding)],
        text:    coding[:display] || admit_source
      )
    end

    def fhir_period(hl7, terrminology)
      #TODO: implement spec
      Fhir::Period.new(
          start: Time.parse(hl7.pv1.admit_date_time.time.to_p),
          end:   hl7.pv1.discharge_date_times.blank? ? nil : Time.parse(hl7.pv1.discharge_date_times.first.time.to_p)
      )
    end

    def fhir_accomodations(hl7, terrminology)
      #Fhir::Encounter::Accomodation.new( bed: pv1_to_fhir_bed(pv1) PV1-3-assigned patient location, Fhir::Location, period: Fhir::Period),
    end

    def fhir_diet(hl7, terrminology)
      # !!! Hl7 not define own codes, so we just passing it to fhir
      DataTypeConverter.ce_to_codeable_concept(hl7.pv1.diet_type) if hl7.pv1.diet_type
    end

    def fhir_special_courtesies(hl7, terrminology)
      #Array[Fhir::CodeableConcept],PV1-16-VIP indicator
      vip_indicator = hl7.pv1.vip_indicator.try(:to_p)
      code          = vip_indicator_to_code(vip_indicator)
      coding        = terrminology.coding(
        'http://hl7.org/fhir/vs/encounter-special-courtesy',
        admit_source_to_code(code, terrminology)
      )
      vip_indicator && Fhir::CodeableConcept.new(
        codings: [Fhir::Coding.new(coding)],
        text:    coding[:display])
    end

    def fhir_special_arrangements(hl7, terrminology)
      #Array[Fhir::CodeableConcept],PV1-15-ambulatory status / OBR-30-transportation mode / OBR-43-planned patient transport comment
    end

    def fhir_discharge_disposition(hl7, terrminology)
      discharge_disposition = hl7.pv1.discharge_disposition.try(:to_p)
      coding                = terrminology.coding(
        'http://hl7.org/fhir/vs/encounter-discharge-disposition',
        discharge_disposition_to_code(discharge_disposition, terrminology)
      )
      discharge_disposition && Fhir::CodeableConcept.new(
        codings: [Fhir::Coding.new(coding)],
        text:    coding[:display])

        #Fhir::CodeableConcept,PV1-36-discharge disposition
    end

    def fhir_re_admission(hl7, terrminology)
      hl7.pv1.re_admission_indicator.try(:to_p) == 'R'
    end

    def fhir_locations(hl7, terrminology)
      [Fhir::Encounter::Location.new(
        location: fhir_location(hl7, terrminology),
        period: Fhir::Period.new(start: DateTime.now, end: DateTime.now)
      )]
    end

    def fhir_location(hl7, terrminology)
      #Fhir::Location,PV1-3-assigned patient location / PV1-6-prior patient location / PV1-11-temporary location / PV1-42-pending location / PV1-43-prior temporary location
=begin
class Fhir::Location < Fhir::Resource
  attribute :text, Fhir::Narrative
  attribute :name, String
  attribute :description, String
  attribute :types, Array[Fhir::CodeableConcept]
  attribute :telecom, Fhir::Contact
  attribute :address, Fhir::Address
  class Position < Fhir::ValueObject
    attribute :longitude, Float
    attribute :latitude, Float
    attribute :altitude, Float
  end
  attribute :position, Position
  resource_reference :provider, [Fhir::Organization]
  attribute :active, Boolean
  resource_reference :part_of, [Fhir::Location]
end
=end
    end

    def fhir_service_provider(hl7, terrminology)
      #Fhir::Organization,PV1-10-hospital service / PL.6 Person Location Type & PL.1 Point of Care (note: V2.x definition is "the treatment or type of surgery that the patient is scheduled to receive"; seems slightly out of alignment with the concept name 'hospital service'. Would not trust that implementations apply this semantic by default)
=begin
class Xon < ::HealthSeven::DataType
  # Organization Name
  attribute :organization_name, St, position: "XON.1"
  # Organization Name Type Code
  attribute :organization_name_type_code, Is, position: "XON.2"
  # ID Number
  attribute :id_number, Nm, position: "XON.3"
  # Check Digit
  attribute :check_digit, Nm, position: "XON.4"
  # Check Digit Scheme
  attribute :check_digit_scheme, Id, position: "XON.5"
  # Assigning Authority
  attribute :assigning_authority, Hd, position: "XON.6"
  # Identifier Type Code
  attribute :identifier_type_code, Id, position: "XON.7"
  # Assigning Facility
  attribute :assigning_facility, Hd, position: "XON.8"
  # Name Representation Code
  attribute :name_representation_code, Id, position: "XON.9"
  # Organization Identifier
  attribute :organization_identifier, St, position: "XON.10"
end
=end
      Fhir::Organization.new(
        text: Fhir::Narrative.new(
          status: 'TODO',
          div: 'TODO'
        ),
        identifiers: Array[Fhir::Identifier],
        name: 'TODO',
        type: Fhir::CodeableConcept,
        telecoms: Array[Fhir::Contact],
        addresses: Array[Fhir::Address],
        part_of: Fhir::Organization,
        contacts: Array[Fhir::Organization::Contact.new(
          purpose: Fhir::CodeableConcept,
          name: Fhir::HumanName,
          telecoms: Array[Fhir::Contact],
          address: Fhir::Address,
          gender: Fhir::CodeableConcept
        )],
          active: Boolean
      )
    end

    def discharge_disposition_to_code(discharge_disposition, terrminology)
      # !!! Add mappings !!! Incomplete
      terrminology.map_concept(
          'http://hl7.org/fhir/v2/vs/0112',
          discharge_disposition,
          'http://hl7.org/fhir/vs/encounter-discharge-disposition'
      )[:code]
    end

    def vip_indicator_to_code(vip_indicator)
      vip_indicator
    end

    def admit_source_to_code(admit_source, terrminology)
      #!!! Incomplete
      terrminology.map_concept(
          'http://hl7.org/fhir/v2/vs/0023',
          admit_source,
          'http://hl7.org/fhir/vs/encounter-admit-source'
      )[:code]
    end
  end
end
