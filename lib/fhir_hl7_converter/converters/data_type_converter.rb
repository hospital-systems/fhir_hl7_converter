module FhirHl7Converter
  module DataTypeConverter
    extend self

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

    def xtn_to_fhir_telecom(xtn, use)
      Fhir::Contact.new(
          system: 'http://hl7.org/fhir/contact-system',
          value: xtn.telephone_number.to_p,
          use: use,
          period: nil#Fhir::Period.new(start: DateTime.now, end: DateTime.now)
      )
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

    #/segment (?) methods

    #temp mapping methods

    def address_type_to_use(address_type)
      {
          'H' => 'home',
          'O' => 'work',
          'C' => 'temp',
          'BA' => 'old'
      }[address_type]
    end
  end
end
