require 'spec_helper'
require 'health_seven'
require 'fhir'
require 'fhir_hl7_converter'
describe FhirHl7Converter::PatientAttributeConverter do
  include HL7SpecHelper

  let(:subject)                              { FhirHl7Converter::PatientAttributeConverter }
  let(:message)                              { fixture('adt_a01') }
  let(:hl7)                                  { HealthSeven::Message.parse(message) }
  let(:gateway)                              { FhirHl7Converter::Factory.hl7_to_fhir(hl7) }
  let(:pid)                                  { hl7.pid }
  let(:nk1s)                                 { hl7.nk1s }
  let(:administrative_sex_v_s_identifier)    { 'http://hl7.org/fhir/vs/administrative-gender' }
  let(:marital_status_code_v_s_identifier)   { 'http://hl7.org/fhir/vs/marital-status' }

  describe '#fhir_gender' do
    it 'should create codeable concept containing gender from hl7 message' do
      gender = subject.fhir_gender(hl7)
      assert_gender(gender, pid.administrative_sex)
    end
  end

  describe '#fhir_birth_date' do
    it 'should create birth date_time from hl7 message' do
      birth_date = subject.fhir_birth_date(hl7)
      birth_date.should == DateTime.parse(pid.date_time_of_birth.time.to_p)
    end
  end

  describe '#fhir_marital_status' do
    it 'should create codeable concept containing marital status from hl7 message' do
      marital_status = subject.fhir_marital_status(hl7)

      marital_status.coding.first.code.should    == pid.marital_status.identifier.to_p
      marital_status.coding.first.display.should == pid.marital_status.identifier.to_p
      marital_status.text.should                  == pid.marital_status.identifier.to_p
    end
  end

  describe '#fhir_deceased' do
    it 'should create death time from hl7 message' do
      deceased = subject.fhir_deceased(hl7)
      deceased.should == DateTime.parse(pid.patient_death_date_and_time.time.to_p)
    end
  end

  describe '#fhir_multiple_birth' do
    it 'should create order of multiple births from hl7 message' do
      subject.fhir_multiple_birth(hl7).should == pid.birth_order.to_p
    end
  end

  example do
    nk1s.first.tap do |nk1|
      contact = subject.nk1_to_fhir_contact(nk1)
      contact.relationship.first.tap do |cc|
        cc.coding.first.tap do |c|
          c.system.should == 'http://hl7.org/fhir/patient-contact-relationship'
          c.code.should == nk1.relationship.identifier.to_p
          c.display;
        end
        cc.coding.last.tap do |c|
          c.system.should == 'http://hl7.org/fhir/patient-contact-relationship'
          c.code.should == nk1.contact_role.identifier.to_p
          c.display;
        end
      end
      nk1.names.first.tap do |xpn|
        contact.name.tap do |n|
          n.family.first.should == xpn.family_name.surname.to_p
          n.given.first.should == [xpn.given_name, xpn.second_and_further_given_names_or_initials_thereof].map(&:to_p).join(', ')
          n.prefix.first.should == xpn.prefix.to_p
          n.suffix.first.should == xpn.suffix.to_p
          n.text.should == (n.given + n.family + n.prefix + n.suffix).join(' ')
          n.period.should be_nil
        end
      end
      nk1.phone_numbers.first.tap do |xtn|
        contact.telecom.first.tap do |c|
          c.system.should == 'http://hl7.org/fhir/contact-system'
          c.value.should == xtn.telephone_number.to_p
          c.use.should == 'home'
          c.period.should be_nil
        end
      end
      nk1.business_phone_numbers.first.tap do |xtn|
        contact.telecom.last.tap do |c|
          c.system.should == 'http://hl7.org/fhir/contact-system'
          c.value.should == xtn.telephone_number.to_p
          c.use.should == 'work'
          c.period.should be_nil
        end
      end
      nk1.addresses.first.tap do |xad|
        assert_address(contact.address, xad)
      end
      assert_gender(contact.gender, nk1.administrative_sex)
    end
  end

  example do
    patient = gateway.patient
    puts patient.to_yaml
  end

  example do
    encounter = gateway.encounter
    puts encounter.to_yaml
  end

  example do
=begin
    PatientAdministration::HL7Gateway::AdmitA01
    .new(config)
    .handle(message)

    pending

    pt = PatientAdministration::PatientUseCase
    .new(config)
    .find(identity)

    pt.should_not be_nil

Patient
Encounter
Location
Practitioner
Organization
=end
  end

  def assert_gender(gender, administrative_sex)
    gender.coding.first.tap do |c|
      c.code.should == administrative_sex.to_p
      c.display.should == administrative_sex.to_p
    end
  end
end
