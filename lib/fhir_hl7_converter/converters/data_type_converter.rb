module FhirHl7Converter
  module DataTypeConverter
    extend self

    def ce_to_codeable_concept(ce)
      primary_coding = Fhir::Coding.new(
        system: ce.name_of_coding_system.try(:to_p),
        code: ce.identifier.try(:to_p),
        display: ce.text.try(:to_p),
        primary: true)

        if (alternate_identifier = ce.alternate_identifier)
          secondary_coding = Fhir::Coding.new(
            system: ce.name_of_alternate_coding_system.try(:to_p),
            code: alternate_identifier.to_p,
            display: ce.alternate_text.try(:to_p),
            primary: false)
        end
        Fhir::CodeableConcept.new(
          coding: [primary_coding, secondary_coding].compact,
          text: primary_coding.display || secondary_coding.display
        )
    end

    def cx_to_fhir_identifier(cx)
      Fhir::Identifier.new(
        use: 'usual',
        label: cx.id_number.to_p,
        system: cx.identifier_type_code.to_p,
        value: cx.id_number.to_p,
        period: nil,
        assigner: nil#[Fhir::Organization]
      )
    end

    def xad_to_fhir_address(xad)
      Fhir::Address.new(
        use: xad.address_type.try(:to_p),
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
          line: [
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

    def xcn_to_fhir_practitioner(xcn)
      families = xcn.family_name.surname.to_p
      givens = [
        xcn.given_name,
        xcn.second_and_further_given_names_or_initials_thereof
      ].compact.map(&:to_p).select{ |n| n.present? }.join(', ')
      prefixes = xcn.prefix.try(:to_p)
      suffixes = xcn.suffix.try(:to_p)
      Fhir::Practitioner.new(
        text: Fhir::Narrative.new(status: 'TODO', div: 'TODO'),
        identifier: [
          Fhir::Identifier.new(
            use: 'usual',
            value: xcn.id_number.to_p,
            label: xcn.id_number.to_p,
            system: nil,
            period: nil,
            assigner: nil
          )],
            name: Fhir::HumanName.new(
              use: xcn.name_type_code.to_p,
              text: [givens, families, prefixes, suffixes].join(' '),#FIXME
              family: [families],
              given: [givens],
              prefix: [prefixes],
              suffix: [suffixes],
              period: nil#Fhir::Period.new(start: DateTime.now, end: DateTime.now)
          ),
            telecom: nil,#Array[Fhir::Contact],
            address: nil,#Fhir::Address,
            gender: nil,#Fhir::CodeableConcept,
            birth_date: nil,#DateTime,
            photo: nil,#Array[Fhir::Attachment],
            organization: nil,#[Fhir::Organization],
            role: nil,#Array[Fhir::CodeableConcept],
            specialty: nil,#Array[Fhir::CodeableConcept],
            period: nil,#Fhir::Period,
            qualification: xcn_to_fhir_practitioner_qualifications(xcn),
            communication: nil#Array[Fhir::CodeableConcept]
      )
    end

    def xcn_to_fhir_practitioner_qualifications(xcn)
      if xcn.degree.try(:to_p).present?
        [
          Fhir::Practitioner::Qualification.new(
            code:
            Fhir::CodeableConcept.new(
              coding: [Fhir::Coding.new(
                system: 'TODO',
                code: xcn.degree.to_p,
                display: xcn.degree.to_p)],
                text: xcn.degree.to_p
            ),
              period: nil,#Fhir::Period,
              issuer: nil#[Fhir::Organization]
          )
        ]
      end
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
        family: [families],
        given: [givens],
        prefix: [prefixes],
        suffix: [suffixes],
        period: nil#Fhir::Period.new(start: DateTime.now, end: DateTime.now)
      )
    end

    def xtn_to_fhir_telecom(xtn, use)
      Fhir::Contact.new(
        system: 'http://hl7.org/fhir/contact-system',
        value: xtn.telephone_number.to_p,
        use: use,
        period: nil#Fhir::Period.new(start: DateTime.now, end: DateTime.now)
      )
    end
  end
end
