require 'spec_helper'
require 'health_seven'
require 'fhir'
require 'fhir_hl7_converter'
describe FhirHl7Converter::DataTypeConverter do
  include HL7SpecHelper

  let(:subject)      { FhirHl7Converter::DataTypeConverter}
  let(:message)      { fixture('adt_a01') }
  let(:hl7)          { HealthSeven::Message.parse(message) }
  let(:pid)          { hl7.pid }
  let(:pv1)          { hl7.pv1 }
  let(:terrminology) { FhirHl7Converter::Factory.hl7_to_fhir(hl7).terrminology }

  example do
    pid.patient_names.first.tap do |xpn|
      name = subject.xpn_to_fhir_name(xpn)
      name.families.first.should == xpn.family_name.surname.to_p
      name.givens.first.should == [xpn.given_name, xpn.second_and_further_given_names_or_initials_thereof].map(&:to_p).join(', ')
      name.prefixes.first.should == xpn.prefix.to_p
      name.suffixes.first.should == xpn.suffix.to_p
      name.text.should == (name.givens + name.families + name.prefixes + name.suffixes).join(' ')
    end
  end

  example do
    pid.patient_addresses.first.tap do |xad|
      address = subject.xad_to_fhir_address(xad, terrminology)
      assert_address(address, xad, terrminology)
    end
  end

  example do
    pid.patient_identifier_lists.first.tap do |cx|
      identifier = subject.cx_to_fhir_identifier(cx)
      identifier.use.should == 'usual'
      identifier.key.should == cx.id_number.to_p
      identifier.label.should == cx.id_number.to_p
      identifier.system.should == cx.identifier_type_code.to_p
    end
  end

  example do
    pid.phone_number_homes.first.tap do |xtn|
      telecom = subject.xtn_to_fhir_telecom(xtn, 'home')
      telecom.system.should == 'http://hl7.org/fhir/contact-system'
      telecom.value.should == xtn.telephone_number.to_p
      telecom.use.should == 'home'
    end
    pid.phone_number_businesses.first.tap do |xtn|
      telecom = subject.xtn_to_fhir_telecom(xtn, 'work')
      telecom.system.should == 'http://hl7.org/fhir/contact-system'
      telecom.value.should == xtn.telephone_number.to_p
      telecom.use.should == 'work'
    end
  end

  example do
    puts pv1.attending_doctors.to_yaml#, Array[Xcn], position: "PV1.7", multiple: true
    puts pv1.referring_doctors.to_yaml#, Array[Xcn], position: "PV1.8", multiple: true
    puts pv1.consulting_doctors.to_yaml#, Array[Xcn], position: "PV1.9", multiple: true
    puts pv1.admitting_doctors.to_yaml#, Array[Xcn], position: "PV1.17", multiple: true
    pv1.attending_doctors.first.tap do |xcn|
      subject.xcn_to_fhir_practitioner(xcn).tap do |p|
        p.text.shoud# Fhir::Narrative
        p.identifiers.should#, Array[Fhir::Identifier]
        p.name.should#, Fhir::HumanName
        p.telecoms.should#, Array[Fhir::Contact]
        p.address.should#, Fhir::Address
        p.gender.should#, Fhir::CodeableConcept
        p.birth_date.should#, DateTime
        p.photos.should#, Array[Fhir::Attachment]
        p.organization.should#, [Fhir::Organization]
        p.roles.should#, Array[Fhir::CodeableConcept]
        p.specialties.should#, Array[Fhir::CodeableConcept]
        p.period.should#, Fhir::Period
        p.qualifications.first.tap do |q|#, Array[Qualification]
          q.code.should#, Fhir::CodeableConcept
          q.period.should#, Fhir::Period
          q.issuer.should# [Fhir::Organization]
        end
        p.communications.should#, Array[Fhir::CodeableConcept]
      end
    end
  end
end
