module FhirHl7Converter
  class Hl7ToFhirConverter
    attr_reader :terrminology

    def initialize(hl7)
      @hl7 = hl7
      @terrminology = Terrminology.api
    end

    def patient
      lans  = hl7_to_lans(@hl7)
      mrg   = hl7_to_mrg(@hl7)
      @patient ||= Fhir::Patient.new(
          text:           pid_to_fhir_text(@hl7.pid),
          identifiers:    pid_to_fhir_identifiers(@hl7.pid),
          names:          pid_to_fhir_names(@hl7.pid),
          telecoms:       pid_to_fhir_telecoms(@hl7.pid),
          gender:         pid_to_fhir_gender(@hl7.pid),
          birth_date:     pid_to_fhir_birth_date(@hl7.pid),
          deceased:       pid_to_fhir_deceased(@hl7.pid),
          addresses:      pid_to_fhir_addresses(@hl7.pid),
          marital_status: pid_to_fhir_marital_status(@hl7.pid),
          multiple_birth: pid_to_fhir_multiple_birth(@hl7.pid),
          photos:         obxes_to_fhir_photos(@hl7.obxes),
          contacts:       nk1s_to_fhir_contacts(@hl7.nk1s),
          animal:         pid_to_fhir_animal(@hl7.pid),
          communications: lans_to_fhir_communications(lans),
          provider:       nil,
          links:          pid_mrg_to_fhir_links(@hl7.pid, mrg),
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
          participants:     pv1_to_fhir_participants(@@hl7.pv1),
          fulfills:         hl7_to_fhir_fulfills(@hl7),
          start:            nil,
          length:           pv1_to_fhir_length(@hl7.pv1),
          reason:           hl7_to_fhir_reason(@hl7),
          indication:       nil,#Fhir::Resource,
          priority:         pv2_to_fhir_priority(@hl7.pv2),
          hospitalization:  hl7_to_fhir_hospitalization(@hl7),
          locations:        nil, #hl7_to_fhir_locations(@hl7),
          service_provider: hl7_to_fhir_service_provider(@hl7),
          part_of:          nil#Fhir::Encounter
      )
    end


    #FIXME move to health_seven to fhir convertation gem
    def message_to_fhir_patient(message)
      object = FhirHl7Converter::Factory.hl7_to_fhir(message_to_hl7(message))

      patient = object.patient

      hl7 = message_to_hl7(message)
      pid = hl7_to_pid(hl7)
      obxes = hl7_to_obxes(hl7)
      nk1s = hl7_to_nk1s(hl7)
      lans = hl7_to_lans(hl7)
      mrg = hl7_to_mrg(hl7)
      Fhir::Patient.new(
          text: pid_to_fhir_text(pid),
          identifiers: pid_to_fhir_identifiers(pid),
          names: pid_to_fhir_names(pid),
          telecoms: pid_to_fhir_telecoms(pid),
          gender: pid_to_fhir_gender(pid),
          birth_date: pid_to_fhir_birth_date(pid),
          deceased: pid_to_fhir_deceased(pid),
          addresses: pid_to_fhir_addresses(pid),
          marital_status: pid_to_fhir_marital_status(pid),
          multiple_birth: pid_to_fhir_multiple_birth(pid),
          photos: obxes_to_fhir_photos(obxes),
          contacts: nk1s_to_fhir_contacts(nk1s),
          animal: pid_to_fhir_animal(pid),
          communications: lans_to_fhir_communications(lans),
          provider: nil,
          links: pid_mrg_to_fhir_links(pid, mrg),
          active: true
      )
    end

    def message_to_hl7(message)
      HealthSeven::Message.parse(message)
    end

    def hl7_to_pid(hl7)
      hl7.pid
    end

    def hl7(message)
      HealthSeven::Message.parse(message)
    end

    def hl7_to_pid(hl7)
      hl7.pid
    end

    def hl7_to_pv1(hl7)
      hl7.pv1
    end

    def hl7_to_pv2(hl7)
      hl7.pv2
    end

    def hl7_to_obxes(hl7)
      hl7.obxes
    end

    def hl7_to_nk1s(hl7)
      hl7.nk1s
    end

    def hl7_to_lans(hl7)
      hl7.lans if hl7.respond_to?(:lans)
    end

    def hl7_to_mrg(hl7)
      hl7.mrg if hl7.respond_to?(:mrg)
    end

    def pid_to_fhir_text(pid)
      Fhir::Narrative.new(
          status: 'TODO',
          div: 'TODO'
      )
    end

    def pid_to_fhir_identifiers(pid)
      pid.patient_identifier_lists.map{ |cx| cx_to_fhir_identifier(cx) }
    end

    def cx_to_fhir_identifier(cx)
      Fhir::Identifier.new(
          use: 'usual',
          key: cx.id_number.to_p,
          label: cx.id_number.to_p,
          system: cx.identifier_type_code.to_p,
          period: nil,
          assigner: nil#[Fhir::Organization]
      )
    end

    def pid_to_fhir_names(pid)
      pid.patient_names.map{ |xpn| xpn_to_fhir_name(xpn) } +
          pid.patient_aliases.map{ |xpn| xpn_to_fhir_name(xpn) }
    end

    def xpn_to_fhir_name(xpn)
      families = xpn.family_name.surname.to_p
      givens = [
          xpn.given_name,
          xpn.second_and_further_given_names_or_initials_thereof
      ].compact.map(&:to_p).select{ |n| n.present? }.join(', ')
      prefixes = xpn.prefix.try(:to_p)
      suffixes = xpn.suffix.try(:to_p)
      Fhir::HumanName.new(
          use: 'TODO',
          text: [givens, families, prefixes, suffixes].join(' '),#FIXME
          families: [families],
          givens: [givens],
          prefixes: [prefixes],
          suffixes: [suffixes],
          period: nil#Fhir::Period.new(start: DateTime.now, end: DateTime.now)
      )
    end

    def pid_to_fhir_telecoms(pid)
      pid.phone_number_homes.map{ |xtn| xtn_to_fhir_telecom(xtn, 'home') } +
          pid.phone_number_businesses.map{ |xtn| xtn_to_fhir_telecom(xtn, 'work') }
    end

    def xtn_to_fhir_telecom(xtn, use)
      Fhir::Contact.new(
          system: 'http://hl7.org/fhir/contact-system',
          value: xtn.telephone_number.to_p,
          use: use,
          period: nil#Fhir::Period.new(start: DateTime.now, end: DateTime.now)
      )
    end

    def pid_to_fhir_gender(pid)
      administrative_sex_to_gender(pid.administrative_sex)
    end

    def nk1_to_fhir_gender(nk1)
      administrative_sex_to_gender(nk1.administrative_sex)
    end

    def administrative_sex_to_gender(administrative_sex)
      sex    = administrative_sex.try(:to_p)
      coding = @terrminology.coding(
          'http://hl7.org/fhir/vs/administrative-gender',
          sex
      )
      sex && Fhir::CodeableConcept.new(
          codings: [Fhir::Coding.new(coding)],
          text:    coding[:display] || sex
      )
    end

    def pid_to_fhir_birth_date(pid)
      datetime = pid.date_time_of_birth.time.try(:to_p)
      datetime && DateTime.parse(datetime)
    end

    def pid_to_fhir_deceased(pid)
      deceased = pid.patient_death_date_and_time.try(:time).try(:to_p)
      deceased.present? && DateTime.parse(deceased) || pid.patient_death_indicator.try(:to_p)
    end

    def pid_to_fhir_addresses(pid)
      pid.patient_addresses.map{ |xad| xad_to_fhir_address(xad) }
    end

    def xad_to_fhir_address(xad)
      Fhir::Address.new(
          use: address_type_to_use(xad.address_type.try(:to_p)),
          text: [
              xad.street_address.try(:street_or_mailing_address),
              xad.street_address.try(:street_name),
              xad.street_address.try(:dwelling_number),
              xad.other_designation,
              xad.city,
              xad.state_or_province,
              xad.zip_or_postal_code,
              xad.country
          ].map(&:to_p).join(' '),
          lines: [
              xad.street_address.try(:street_or_mailing_address),
              xad.street_address.try(:street_name),
              xad.street_address.try(:dwelling_number),
              xad.other_designation
          ].map(&:to_p),
          city: xad.city.to_p,
          state: xad.state_or_province.to_p,
          zip: xad.zip_or_postal_code.to_p,
          country: xad.country.to_p,
          period: nil#Fhir::Period.new(start: DateTime.now, end: DateTime.now)
      )
    end

    def pid_to_fhir_marital_status(pid)
      marital_status = pid.marital_status.try(:identifier).try(:to_p)
      coding         = @terrminology.coding(
          'http://hl7.org/fhir/vs/marital-status',
          marital_status
      )
      marital_status && Fhir::CodeableConcept.new(
          codings: [Fhir::Coding.new(coding)],
          text:    coding[:display]
      )
    end

    def pid_to_fhir_multiple_birth(pid)
      pid.birth_order.try(:to_p) || pid.multiple_birth_indicator.try(:to_p)
    end

    def obxes_to_fhir_photos(obxes)
      obxes.first.try(:observation_values)
      Fhir::Attachment.new(
          content_type: 'TODO',
          language: 'TODO',
          data: 'TODO',
          url: 'TODO',
          size: 10,
          hash: 'TODO',
          title: 'TODO'
      )
    end

    def nk1s_to_fhir_contacts(nk1s)
      nk1s.map{ |nk1| nk1_to_fhir_contact(nk1) }
    end

    def nk1_to_fhir_contact(nk1)
      Fhir::Patient::Contact.new(
          relationships: [
              Fhir::CodeableConcept.new(
                  codings: [
                      Fhir::Coding.new(
                          system: 'http://hl7.org/fhir/patient-contact-relationship',
                          code: nk1.relationship.identifier.to_p,
                          display: nk1.relationship.identifier.to_p
                      ),
                      Fhir::Coding.new(
                          system: 'http://hl7.org/fhir/patient-contact-relationship',
                          code: nk1.contact_role.identifier.to_p,
                          display: nk1.relationship.identifier.to_p
                      )
                  ],
                  text: [nk1.relationship.identifier.to_p, nk1.contact_role.identifier.to_p].join(' ')
              )
          ],
          name: xpn_to_fhir_name(nk1.names.first),
          telecoms: (
          nk1.phone_numbers.map{ |xtn| xtn_to_fhir_telecom(xtn, 'home') } +
              nk1.business_phone_numbers.map{ |xtn| xtn_to_fhir_telecom(xtn, 'work') }
          ),
          address: xad_to_fhir_address(nk1.addresses.first),
          gender: nk1_to_fhir_gender(nk1),
          organization: nil#, [Fhir::Organization]
      )
      #organizationNK1-13, NK1-30, NK1-31, NK1-32, NK1-41
      #nk1.organization_name_nk1s
      #nk1.contact_person_s_names
      #nk1.contact_person_s_telephone_numbers
      #nk1.contact_person_s_addresses
    end

    def pid_to_fhir_animal(pid)
      pid.species_code
      pid.strain
      Fhir::Patient::Animal.new(
          species: Fhir::CodeableConcept.new(
              codings: [Fhir::Coding.new(
                            system: 'TODO',
                            code: 'TODO',
                            display: 'TODO'
                        )],
              text: 'TODO'
          ),
          breed: Fhir::CodeableConcept.new(
              codings: [Fhir::Coding.new(
                            system: 'TODO',
                            code: 'TODO',
                            display: 'TODO'
                        )],
              text: 'TODO'
          ),
          gender_status: Fhir::CodeableConcept.new(
              codings: [Fhir::Coding.new(
                            system: 'TODO',
                            code: 'TODO',
                            display: 'TODO'
                        )],
              text: 'TODO'
          )
      )
    end

    def lans_to_fhir_communications(lans)
      lans.map{ |lan| lan_to_fhir_communication(lan) } if lans
    end

    def lan_to_fhir_communications(lan)
      lan.language_code
      Fhir::CodeableConcept.new(
          codings: [Fhir::Coding.new(
                        system: 'TODO',
                        code: 'TODO',
                        display: 'TODO'
                    )],
          text: 'TODO'
      )
    end

    def pid_mrg_to_fhir_links(pid, mrg)
      pid.patient_identifier_lists
      mrg.try(:prior_patient_identifier_lists)
      nil
    end

    def message_to_fhir_encounter(message)
      hl7 = message_to_hl7(message)
      pv1 = hl7_to_pv1(hl7)
      pv2 = hl7_to_pv2(hl7)
      Fhir::Encounter.new(
          text: pv1_to_fhir_text(pv1),
          identifiers: pv1_to_fhir_identifiers(pv1),
          status: hl7_to_fhir_status(hl7),
          encounter_class: pv1_to_fhir_class(pv1),
          types: pv1_to_fhir_types(pv1),
          subject: message_to_fhir_patient(message),
          participants: pv1_to_fhir_participants(pv1),
          fulfills: hl7_to_fhir_fulfills(hl7),
          start: nil,
          length: pv1_to_fhir_length(pv1),
          reason: hl7_to_fhir_reason(hl7),
          indication: nil,#Fhir::Resource,
          priority: pv2_to_fhir_priority(pv2),
          hospitalization: hl7_to_fhir_hospitalization(hl7),
          locations: hl7_to_fhir_locations(hl7),
          service_provider: hl7_to_fhir_service_provider(hl7),
          part_of: nil#Fhir::Encounter
      )
    end

    def pv1_to_fhir_text(pv1)
      #Fhir::Narrative
    end

    def pv1_to_fhir_identifiers(pv1)
      [cx_to_fhir_identifier(pv1.visit_number)] if pv1.visit_number
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
=begin
        [
          Fhir::Encounter::Participant.new(
            types: Array[Fhir::Code],# PV1-7, PV1-8, PV1-9, PV1-17
            practitioner: Fhir::Practitioner#Мое предположение что надо брать данные из: PV1-7, PV1-8, PV1-9, PV1-17
          )
        ],
=end
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
      cx_to_fhir_identifier(pv1.preadmit_number) if pv1.preadmit_number
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
