require 'spec_helper'
require 'health_seven'
require 'fhir'
require 'fhir_hl7_converter'
describe FhirHl7Converter::DataTypeConverter do
  include HL7SpecHelper

  let(:subject)      { FhirHl7Converter::DataTypeConverter }
  let(:message)      { fixture('adt_a01') }
  let(:hl7)          { HealthSeven::Message.parse(message) }
  let(:pid)          { hl7.pid }
  let(:pv1)          { hl7.pv1 }

  describe '#ce_to_codeable_concept' do
    it 'should create fhir codable concept from ce hl7 data type' do
      hl7.pv1.diet_type.tap do |ce|
        subject.ce_to_codeable_concept(ce).tap do |cc|
          cc.coding.count.should == 2
          cc.coding.first.tap do |pc|
            pc.system.should == ce.name_of_coding_system.to_p
            pc.version.should be_nil
            pc.code.should == ce.identifier.to_p
            pc.display.should == ce.text.to_p
            pc.primary.should be_true
            pc.value_set.should be_nil
          end
          cc.coding.last.tap do |sc|
            sc.system.should == ce.name_of_alternate_coding_system.to_p
            sc.version.should be_nil
            sc.code.should == ce.alternate_identifier.to_p
            sc.display.should == ce.alternate_text.to_p
            sc.primary.should be_false
            sc.value_set.should be_nil
          end
          cc.text.should == ce.text.to_p
        end
      end
    end
  end

  describe '#cx_to_fhir_identifier' do
    it 'should create fhir identifier from cx segment' do
      pid.patient_identifier_lists.first.tap do |cx|
        identifier = subject.cx_to_fhir_identifier(cx)
        identifier.use.should == 'usual'
        identifier.label.should == cx.id_number.to_p
        identifier.system.should == cx.identifier_type_code.to_p
        identifier.value.should == cx.id_number.to_p
        identifier.period.should be_nil
        identifier.assigner.should be_nil
      end
    end
  end

  describe '#xad_to_fhir_address' do
    it 'should create fhir address from xad segment' do
      pid.patient_addresses.first.tap do |xad|
        address = subject.xad_to_fhir_address(xad)
        assert_address(address, xad)
      end
    end
  end

  describe '#xcn_to_fhir_practitioner' do
    it 'should create fhir practitioner from xcn segment' do
      #puts pv1.attending_doctors.to_yaml#, Array[Xcn], position: "PV1.7", multiple: true
      #puts pv1.referring_doctors.to_yaml#, Array[Xcn], position: "PV1.8", multiple: true
      #puts pv1.consulting_doctors.to_yaml#, Array[Xcn], position: "PV1.9", multiple: true
      #puts pv1.admitting_doctors.to_yaml#, Array[Xcn], position: "PV1.17", multiple: true
      pv1.attending_doctors.first.tap do |xcn|
        subject.xcn_to_fhir_practitioner(xcn).tap do |p|
          #p.text.should# Fhir::Narrative
          p.identifier.first.tap do |i|
            i.value.should == xcn.id_number.to_p
            #puts xcn.identifier_type_code.to_yaml
            #13Identifier Type CodeableConceptPractitionerPractitioner.identifier.value
            #puts xcn.effective_date.to_yaml
            #puts xcn.expiration_date.to_yaml
            i.period#
            i.period#
            #puts xcn.name_validity_range.to_yaml
            #17PersonName Validity RangePractitioner.identifier.period
            #puts xcn.assigning_facility.to_yaml
            #14Assigning FacilityMaybe Practitioner.identifier.assigner
          end
          p.name.tap do |n|
            n.family.first.should == xcn.family_name.surname.to_p
            n.given.first.should == xcn.given_name.to_p + ', ' + xcn.second_and_further_given_names_or_initials_thereof.to_p
            n.suffix.first.should == xcn.suffix.to_p
            n.prefix.first.should == xcn.prefix.to_p
            n.use.should == xcn.name_type_code.to_p
            #puts xcn.name_assembly_order.to_yaml
            #18Name Assembly OrderHelps to build Practitioner.name.text
            #puts xcn.name_representation_code.to_yaml
            #15Name Representation CodeableConceptPractitionerPractitionerHelps to build Practitioner.name.text
          end
          p.qualification.first.tap do |q|
            q.code.coding.first.code.should == xcn.degree.to_p
            #q.code.coding.second.code.should == xcn.professional_suffix.to_p
            #q.period.should#, Fhir::Period
            #q.issuer.should# [Fhir::Organization]
            #puts xcn.assigning_agency_or_department.to_yaml
            #23Assigning Agency or DepartmentPractitioner.qualification.issuer
            #puts xcn.assigning_jurisdiction.to_yaml
            #22Assigning JurisdictionPractitioner.qualification.issuer
          end
          #9Assigning AuthorityPractitioner.identifier.system and/or Practitioner.name.assigner
          # Assigning Authority
          #puts xcn.assigning_authority.namespace_id.to_p
          p.address.should#, Fhir::Address
          p.gender.should#, Fhir::CodeableConcept
          p.birth_date.should#, DateTime
          p.photo.should#, Array[Fhir::Attachment]
          p.organization.should#, [Fhir::Organization]
          p.role.should#, Array[Fhir::CodeableConcept]
          p.specialty.should#, Array[Fhir::CodeableConcept]
          p.period.should#, Fhir::Period
          p.communication.should#, Array[Fhir::CodeableConcept]
        end
        #puts xcn.source_table.to_yaml
        #puts xcn.identifier_check_digit.to_yaml
        #puts xcn.check_digit_scheme.to_yaml
        #puts xcn.name_context.to_yaml
      end
    end
  end

  describe '#xcn_to_fhir_practitioner_qualifications' do
  end

  describe '#xpn_to_fhir_name' do
    it 'should create fhir name from xpn segment' do
      pid.patient_names.first.tap do |xpn|
        name = subject.xpn_to_fhir_name(xpn)
        name.family.first.should == xpn.family_name.surname.to_p
        name.given.first.should == [xpn.given_name, xpn.second_and_further_given_names_or_initials_thereof].map(&:to_p).join(', ')
        name.prefix.first.should == xpn.prefix.to_p
        name.suffix.first.should == xpn.suffix.to_p
        name.text.should == (name.given + name.family + name.prefix + name.suffix).join(' ')
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
end
