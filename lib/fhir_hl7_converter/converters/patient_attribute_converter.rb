module FhirHl7Converter
  module PatientAttributeConverter
    extend self

    def fhir_text(hl7)
      Fhir::Narrative.new(status: 'TODO', div: 'TODO')
    end

    def fhir_identifiers(hl7)
      hl7_to_pid(hl7).patient_identifier_lists.map{ |cx| DataTypeConverter.cx_to_fhir_identifier(cx) }
    end

    def fhir_names(hl7)
      hl7_to_pid(hl7).patient_names.map{ |xpn| DataTypeConverter.xpn_to_fhir_name(xpn) } +
          hl7_to_pid(hl7).patient_aliases.map{ |xpn| DataTypeConverter.xpn_to_fhir_name(xpn) }
    end

    def fhir_telecoms(hl7)
      hl7_to_pid(hl7).phone_number_homes.map{ |xtn| DataTypeConverter.xtn_to_fhir_telecom(xtn, 'home') } +
          hl7_to_pid(hl7).phone_number_businesses.map{ |xtn| DataTypeConverter.xtn_to_fhir_telecom(xtn, 'work') }
    end

    def fhir_gender(hl7)
      administrative_sex_to_gender(hl7_to_pid(hl7).administrative_sex)
    end

    def fhir_birth_date(hl7)
      datetime = hl7_to_pid(hl7).date_time_of_birth.time.try(:to_p)
      datetime && DateTime.parse(datetime)
    end

    def fhir_deceased(hl7)
      deceased = hl7_to_pid(hl7).patient_death_date_and_time.try(:time).try(:to_p)
      deceased.present? && DateTime.parse(deceased) || pid.patient_death_indicator.try(:to_p)
    end

    def fhir_addresses(hl7)
      hl7_to_pid(hl7).patient_addresses.map{ |xad| DataTypeConverter.xad_to_fhir_address(xad) }
    end

    def fhir_marital_status(hl7)
      marital_status = hl7_to_pid(hl7).marital_status.try(:identifier).try(:to_p)
      coding = { system: 'http://hl7.org/fhir/v2/0002', code: marital_status, display: marital_status }
      marital_status && Fhir::CodeableConcept.new(coding: [Fhir::Coding.new(coding)], text: coding[:display])
    end

    def fhir_multiple_birth(hl7)
      hl7_to_pid(hl7).birth_order.try(:to_p) || hl7_to_pid(hl7).multiple_birth_indicator.try(:to_p)
    end

    def fhir_photos(hl7)
      hl7.obxes.first.try(:observation_values)
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

    def fhir_contacts(hl7)
      hl7.nk1s.map{ |nk1| nk1_to_fhir_contact(nk1) }
    end


    def fhir_animal(hl7)
      hl7_to_pid(hl7).species_code
      hl7_to_pid(hl7).strain
      Fhir::Patient::Animal.new(
          species: Fhir::CodeableConcept.new(
              coding: [Fhir::Coding.new(
                            system: 'TODO',
                            code: 'TODO',
                            display: 'TODO'
                        )],
              text: 'TODO'
          ),
          breed: Fhir::CodeableConcept.new(
              coding: [Fhir::Coding.new(
                            system: 'TODO',
                            code: 'TODO',
                            display: 'TODO'
                        )],
              text: 'TODO'
          ),
          gender_status: Fhir::CodeableConcept.new(
              coding: [Fhir::Coding.new(
                            system: 'TODO',
                            code: 'TODO',
                            display: 'TODO'
                        )],
              text: 'TODO'
          )
      )
    end

    def fhir_communications(hl7)
      hl7_to_lans(hl7).map{ |lan| lan_to_fhir_communication(lan) } if hl7_to_lans(hl7)
    end


    def fhir_links(hl7)
      hl7_to_pid(hl7).patient_identifier_lists
      hl7_to_mrg(hl7).try(:prior_patient_identifier_lists)
      nil
    end

    def hl7_to_pid(hl7)
      hl7.pid
    end

    def hl7_to_lans(hl7)
      hl7.lans if hl7.respond_to?(:lans)
    end

    def hl7_to_mrg(hl7)
      hl7.mrg if hl7.respond_to?(:mrg)
    end

    def nk1_to_fhir_contact(nk1)
      Fhir::Patient::Contact.new(
          relationship: [
              Fhir::CodeableConcept.new(
                  coding: [
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
          name: DataTypeConverter.xpn_to_fhir_name(nk1.names.first),
          telecom: (
          nk1.phone_numbers.map{ |xtn| DataTypeConverter.xtn_to_fhir_telecom(xtn, 'home') } +
              nk1.business_phone_numbers.map{ |xtn| DataTypeConverter.xtn_to_fhir_telecom(xtn, 'work') }
          ),
          address: DataTypeConverter.xad_to_fhir_address(nk1.addresses.first),
          gender: nk1_to_fhir_gender(nk1),
          organization: nil#, [Fhir::Organization]
      )
      #organizationNK1-13, NK1-30, NK1-31, NK1-32, NK1-41
      #nk1.organization_name_nk1s
      #nk1.contact_person_s_names
      #nk1.contact_person_s_telephone_numbers
      #nk1.contact_person_s_addresses
    end

    def nk1_to_fhir_gender(nk1)
      administrative_sex_to_gender(nk1.administrative_sex)
    end

    def lan_to_fhir_communication(lan)
      #lan.language_code
      Fhir::CodeableConcept.new(
          codings: [Fhir::Coding.new(
                        system: 'TODO',
                        code: 'TODO',
                        display: 'TODO'
                    )],
          text: 'TODO'
      )
    end

    def administrative_sex_to_gender(administrative_sex)
      sex = administrative_sex.try(:to_p)
      coding = { system: 'http://hl7.org/fhir/v2/vs/0001', code: sex, display: sex }
      sex && Fhir::CodeableConcept.new(
          coding: [Fhir::Coding.new(coding)],
          text:    coding[:display] || sex
      )
    end
  end
end
