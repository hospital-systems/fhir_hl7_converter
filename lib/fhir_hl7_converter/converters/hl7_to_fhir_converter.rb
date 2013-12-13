module FhirHl7Converter
  class Hl7ToFhirConverter
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
        text:             pv1_to_fhir_text(@hl7.pv1),
        identifiers:      pv1_to_fhir_identifiers(@hl7.pv1),
        status:           hl7_to_fhir_status(@hl7),
        encounter_class:  pv1_to_fhir_class(@hl7.pv1),
        types:            pv1_to_fhir_types(@hl7.pv1),
        subject:          patient,
        participants:     pv1_to_fhir_participants(@hl7.pv1),
        fulfills:         hl7_to_fhir_fulfills(@hl7),
        start:            nil,
        length:           pv1_to_fhir_length(@hl7.pv1),
        reason:           hl7_to_fhir_reason(@hl7),
        indication:       nil,#Fhir::Resource,
        priority:         pv2_to_fhir_priority(@hl7.pv2),
        hospitalization:  hl7_to_fhir_hospitalization(@hl7),
        locations:        hl7_to_fhir_locations(@hl7),
        service_provider: hl7_to_fhir_service_provider(@hl7),
        part_of:          nil#Fhir::Encounter
      )
    end

    def message_to_hl7(message)
      HealthSeven::Message.parse(message)
    end

    def hl7(message)
      HealthSeven::Message.parse(message)
    end


    def hl7_to_pv1(hl7)
      hl7.pv1
    end

    def hl7_to_pv2(hl7)
      hl7.pv2
    end

    def pv1_to_fhir_text(pv1)
      #Fhir::Narrative
    end

    def pv1_to_fhir_identifiers(pv1)
      [DataTypeConverter.cx_to_fhir_identifier(pv1.visit_number)] if pv1.visit_number
    end

    def hl7_to_fhir_status(hl7)
      #Fhir::Code,No clear equivalent in V2.x; active/finished could be inferred from PV1-44, PV1-45, PV2-24; inactive could be inferred from PV2-16
    end

    def pv1_to_fhir_class(pv1)
      patient_class = pv1.patient_class.try(:to_p)
      patient_class && Fhir::Code.new(patient_class)
    end

    def pv1_to_fhir_types(pv1)
      admission_type = pv1.admission_type.try(:to_p)
      coding         = @terrminology.coding(
        'http://hl7.org/fhir/v2/vs/0007',
        admission_type
      )
      admission_type && [
        Fhir::CodeableConcept.new(
          codings: [Fhir::Coding.new(coding)],
          text:    coding[:display] || admission_type
        )]
    end

    def pv1_to_fhir_participants(pv1)
      pv1.attending_doctors.map{ |xcn| xcn_to_fhir_participant(xcn, 'attending') } +
        pv1.referring_doctors.map{ |xcn| xcn_to_fhir_participant(xcn, 'referrer') } +
        pv1.consulting_doctors.map{ |xcn| xcn_to_fhir_participant(xcn, 'consulting') } +
        pv1.admitting_doctors.map{ |xcn| xcn_to_fhir_participant(xcn, 'admitter') }
    end


    def xcn_to_fhir_participant(xcn, code)
      Fhir::Practitioner::Participant.new(
        types: [code],
        practitioner: xcn_to_fhir_practitioner(xcn)
      )
    end

    def xcn_to_fhir_practitioner(xcn)
      Fhir::Practitioner.new(
        text: Fhir::Narrative,
        identifiers: Array[Fhir::Identifier],
        name: Fhir::HumanName,
        telecoms: Array[Fhir::Contact],
        address: Fhir::Address,
        gender: Fhir::CodeableConcept,
        birth_date: DateTime,
        photos: Array[Fhir::Attachment],
        organization: [Fhir::Organization],
        roles: Array[Fhir::CodeableConcept],
        specialties: Array[Fhir::CodeableConcept],
        period: Fhir::Period,
        qualifications: [
          Fhir::Practitioner::Qualification.new(
            code: Fhir::CodeableConcept,
            period: Fhir::Period,
            issuer: [Fhir::Organization]
          )
        ],
          communications: Array[Fhir::CodeableConcept]
      )
    end

    def pv1_to_fhir_length(pv1)
      #Fhir::Quantity,(PV1-45 less PV1-44) iff ( (PV1-44 not empty) and (PV1-45 not empty) ); units in minutes
    end

    def hl7_to_fhir_reason(hl7)
      #*Fhir::Type[String, Fhir::CodeableConcept],EVN-4-event reason code / PV2-3-admit reason (note: PV2-3 is nominally constrained to inpatient admissions; V2.x makes no vocabulary suggestions for PV2-3; would not expect PV2 segment or PV2-3 to be in use in all implementations
    end

    def pv2_to_fhir_priority(pv2)
      #Fhir::CodeableConcept,PV2-25-visit priority code
    end

    def hl7_to_fhir_fulfills(hl7)
      nil#Fhir::Resource,SCH-1-placer appointment ID / SCH-2-filler appointment ID
    end

    def hl7_to_fhir_hospitalization(hl7)
      Fhir::Encounter::Hospitalization.new(
        pre_admission_identifier: pv1_to_fhir_pre_admission_identifier(hl7.pv1),
        origin: nil,#Fhir::Location,
        admit_source: pv1_to_admit_source(hl7.pv1),
        period: hl7_to_fhir_period(hl7),
        accomodations: pv1_to_fhir_accomodations(hl7.pv1),
        diet: pv1_to_diet(hl7.pv1),
        special_courtesies: pv1_to_fhir_special_courtesies(hl7.pv1),
        special_arrangements: pv1_to_fhir_special_arrangements(hl7),
        destination: nil,#Fhir::Location,
        discharge_disposition: pv1_to_discharge_disposition(hl7.pv1),
        re_admission: pv1_to_fhir_re_admission(hl7.pv1)
      )
    end

    def pv1_to_fhir_pre_admission_identifier(pv1)
      DataTypeConverter.cx_to_fhir_identifier(pv1.preadmit_number) if pv1.preadmit_number
    end

    def pv1_to_admit_source(pv1)
      #Fhir::CodeableConcept,PV1-14-admit source
      admit_source = pv1.admit_source.try(:to_p)
      coding       = @terrminology.coding(
        'http://hl7.org/fhir/vs/encounter-admit-source',
        admit_source_to_code(admit_source)
      )
      admit_source && Fhir::CodeableConcept.new(
        codings: [Fhir::Coding.new(coding)],
        text:    coding[:display] || admit_source
      )
    end

    def hl7_to_fhir_period(hl7)
      #Fhir::Period,PV2-11-actual length of inpatient stay / PV1-44-admit date/time / PV1-45-discharge date/time
    end

    def pv1_to_fhir_accomodations(pv1)
      #Fhir::Encounter::Accomodation.new( bed: pv1_to_fhir_bed(pv1) PV1-3-assigned patient location, Fhir::Location, period: Fhir::Period),
    end

    def ce_to_codeable_concept(ce)
      primary_coding = Fhir::Coding.new(
        system: ce.name_of_coding_system.try(:to_p),
        code: ce.identifier.try(:to_p),
        display: ce.text.try(:to_p))

        if (alternate_identifier = ce.alternate_identifier)
          secondary_coding = Fhir::Coding.new(
            system: ce.name_of_alternate_coding_system.try(:to_p),
            code: alternate_identifier.to_p,
            display: ce.alternate_text.try(:to_p))
        end
        Fhir::CodeableConcept.new(
          codings: [primary_coding, secondary_coding].compact,
          text: primary_coding.display || secondary_coding.display
        )
    end

    def pv1_to_diet(pv1)
      # !!! Hl7 not define own codes, so we just passing it to fhir
      ce_to_codeable_concept(pv1.diet_type) if pv1.diet_type
    end

    def pv1_to_fhir_special_courtesies(pv1)
      #Array[Fhir::CodeableConcept],PV1-16-VIP indicator
      vip_indicator = pv1.vip_indicator.try(:to_p)
      code          = vip_indicator_to_code(vip_indicator)
      coding        = @terrminology.coding(
        'http://hl7.org/fhir/vs/encounter-special-courtesy',
        admit_source_to_code(code)
      )
      vip_indicator && Fhir::CodeableConcept.new(
        codings: [Fhir::Coding.new(coding)],
        text:    coding[:display])
    end

    def pv1_to_fhir_special_arrangements(hl7)
      #Array[Fhir::CodeableConcept],PV1-15-ambulatory status / OBR-30-transportation mode / OBR-43-planned patient transport comment
    end

    def pv1_to_discharge_disposition(pv1)
      discharge_disposition = pv1.discharge_disposition.try(:to_p)
      coding                = @terrminology.coding(
        'http://hl7.org/fhir/vs/encounter-discharge-disposition',
        discharge_disposition_to_code(discharge_disposition)
      )
      discharge_disposition && Fhir::CodeableConcept.new(
        codings: [Fhir::Coding.new(coding)],
        text:    coding[:display])

        #Fhir::CodeableConcept,PV1-36-discharge disposition
    end

    def pv1_to_fhir_re_admission(pv1)
      pv1.re_admission_indicator.try(:to_p) == 'R'
    end

    def hl7_to_fhir_locations(hl7)
      [Fhir::Encounter::Location.new(
        location: pv1_to_fhir_location(hl7.pv1),
        period: Fhir::Period.new(start: DateTime.now, end: DateTime.now)
      )]
    end

    def pv1_to_fhir_location(pv1)
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

    def hl7_to_fhir_service_provider(hl7)
      #Fhir::Organization,PV1-10-hospital service / PL.6 Person Location Type & PL.1 Point of Care (note: V2.x definition is "the treatment or type of surgery that the patient is scheduled to receive"; seems slightly out of alignment with the concept name 'hospital service'. Would not trust that implementations apply this semantic by default)
    end

    def discharge_disposition_to_code(discharge_disposition)
      # !!! Add mappings !!! Incomplete
      {'01' => 'home'}[discharge_disposition]
    end

    def address_type_to_use(address_type)
      {
        'H' => 'home',
        'O' => 'work',
        'C' => 'temp',
        'BA' => 'old'
      }[address_type]
    end

    def vip_indicator_to_code(vip_indicator)
      vip_indicator
    end

    def admit_source_to_code(admit_source)
      #!!! Incomplete
      {'7' => 'emd'}[admit_source]
    end
  end
end
