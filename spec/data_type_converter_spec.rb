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

  describe '#xpn_to_fhir_name' do
    it 'should create fhir name from xpn segment' do
      pid.patient_names.first.tap do |xpn|
        name = subject.xpn_to_fhir_name(xpn)
        name.families.first.should == xpn.family_name.surname.to_p
        name.givens.first.should == [xpn.given_name, xpn.second_and_further_given_names_or_initials_thereof].map(&:to_p).join(', ')
        name.prefixes.first.should == xpn.prefix.to_p
        name.suffixes.first.should == xpn.suffix.to_p
        name.text.should == (name.givens + name.families + name.prefixes + name.suffixes).join(' ')
      end
    end
  end

  describe '#xad_to_fhir_address' do
    it 'should create fhir address from xad segment' do
      pid.patient_addresses.first.tap do |xad|
        address = subject.xad_to_fhir_address(xad, terrminology)
        assert_address(address, xad, terrminology)
      end
    end
  end

  describe '#cx_to_fhir_identifier' do
    it 'should create fhir identifier from cx segment' do
      pid.patient_identifier_lists.first.tap do |cx|
        identifier = subject.cx_to_fhir_identifier(cx)
        identifier.use.should == 'usual'
        identifier.key.should == cx.id_number.to_p
        identifier.label.should == cx.id_number.to_p
        identifier.system.should == cx.identifier_type_code.to_p
      end
    end
  end

  describe '#xtn_to_fhir_telecom' do
    it 'should create fhir telecom from xtn segment' do
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
  end

  describe '#xcn_to_fhir_practitioner' do
    it 'should create fhir practitioner from xcn segment' do
      puts pv1.attending_doctors.to_yaml#, Array[Xcn], position: "PV1.7", multiple: true
      puts pv1.referring_doctors.to_yaml#, Array[Xcn], position: "PV1.8", multiple: true
      puts pv1.consulting_doctors.to_yaml#, Array[Xcn], position: "PV1.9", multiple: true
      puts pv1.admitting_doctors.to_yaml#, Array[Xcn], position: "PV1.17", multiple: true
      pv1.attending_doctors.first.tap do |xcn|
        subject.xcn_to_fhir_practitioner(xcn).tap do |p|
          #p.text.should# Fhir::Narrative
          p.identifiers.first.key.should == xcn.id_number.to_p
          p.name.tap do |n|
            n.families.first.should == xcn.family_name.surname.to_p
            n.givens.first.should == xcn.given_name.to_p + ', ' + xcn.second_and_further_given_names_or_initials_thereof.to_p
            n.suffixes.first.should == xcn.suffix.to_p
            n.prefixes.first.should == xcn.prefix.to_p
          end
          p.qualifications.first.tap do |q|
            q.code.codings.first.code.should == xcn.degree.to_p
            #q.period.should#, Fhir::Period
            #q.issuer.should# [Fhir::Organization]
          end
          p.address.should#, Fhir::Address
          p.gender.should#, Fhir::CodeableConcept
          p.birth_date.should#, DateTime
          p.photos.should#, Array[Fhir::Attachment]
          p.organization.should#, [Fhir::Organization]
          p.roles.should#, Array[Fhir::CodeableConcept]
          p.specialties.should#, Array[Fhir::CodeableConcept]
          p.period.should#, Fhir::Period
          p.communications.should#, Array[Fhir::CodeableConcept]
        end
=begin
class Xcn < ::HealthSeven::DataType
  # Source Table
  attribute :source_table, Is, position: "XCN.8"
  # Assigning Authority
  attribute :assigning_authority, Hd, position: "XCN.9"
  # Name Type Code
  attribute :name_type_code, Id, position: "XCN.10"
  # Identifier Check Digit
  attribute :identifier_check_digit, St, position: "XCN.11"
  # Check Digit Scheme
  attribute :check_digit_scheme, Id, position: "XCN.12"
  # Identifier Type Code
  attribute :identifier_type_code, Id, position: "XCN.13"
  # Assigning Facility
  attribute :assigning_facility, Hd, position: "XCN.14"
  # Name Representation Code
  attribute :name_representation_code, Id, position: "XCN.15"
  # Name Context
  attribute :name_context, Ce, position: "XCN.16"
  # Name Validity Range
  attribute :name_validity_range, Dr, position: "XCN.17"
  # Name Assembly Order
  attribute :name_assembly_order, Id, position: "XCN.18"
  # Effective Date
  attribute :effective_date, Ts, position: "XCN.19"
  # Expiration Date
  attribute :expiration_date, Ts, position: "XCN.20"
  # Professional Suffix
  attribute :professional_suffix, St, position: "XCN.21"
  # Assigning Jurisdiction
  attribute :assigning_jurisdiction, Cwe, position: "XCN.22"
  # Assigning Agency or Department
  attribute :assigning_agency_or_department, Cwe, position: "XCN.23"
end
1. XCN – this table summarises the mappings from XCN to practitioner:
8Source TableNo equivalent in FHIR (e.g. extension if really necessary)
9Assigning AuthorityPractitioner.identifier.system and/or Practitioner.name.assigner
10Name Type CodeableConceptPractitioner.name.use
11Identifier Check DigitNo equivalent in FHIR (e.g. extension if really necessary)
12Check Digit SchemeNo equivalent in FHIR (e.g. extension if really necessary)
13Identifier Type CodeableConceptPractitionerPractitioner.identifier.value
14Assigning FacilityMaybe Practitioner.identifier.assigner
15Name Representation CodeableConceptPractitionerPractitionerHelps to build Practitioner.name.text
17PersonName Validity RangePractitioner.identifier.period
18Name Assembly OrderHelps to build Practitioner.name.text
19Effective DateTimePractitioner.identifier.period
20Expiration DateTimePractitionerPractitioner.identifier.period
21Professional SuffixPractitioner.qualification.code
22Assigning JurisdictionPractitioner.qualification.issuer
23Assigning Agency or DepartmentPractitioner.qualification.issuer
24Security CheckNo equivalent in FHIR (e.g. extension if really necessary)
25Security Check SchemeNoNo equivalent in FHIR (e.g. extension if really necessary)
=end
      end
    end
  end
end
