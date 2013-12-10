require 'spec_helper'
require 'health_seven'
describe 'PatientAdministration' do
  include HL7SpecHelper

  let(:config) { nil }
  let(:message) { fixture('adt_a01') }
  let(:gateway) { PatientAdministration::HL7Gateway::AdmitA01.new(config) }
  let(:hl7) { HealthSeven::Message.parse(message) }
  let(:pid) { hl7.pid }
  let(:nk1s) { hl7.nk1s }
  let(:pv1) { hl7.pv1 }

  example do
    pid.patient_names.first.tap do |xpn|
      name = gateway.xpn_to_fhir_name(xpn)
      name.families.first.should == xpn.family_name.surname.to_p
      name.givens.first.should == [xpn.given_name, xpn.second_and_further_given_names_or_initials_thereof].map(&:to_p).join(', ')
      name.prefixes.first.should == xpn.prefix.to_p
      name.suffixes.first.should == xpn.suffix.to_p
      name.text.should == (name.givens + name.families + name.prefixes + name.suffixes).join(' ')
    end
  end

  example do
    pid.patient_addresses.first.tap do |xad|
      address = gateway.xad_to_fhir_address(xad)
      assert_address(address, xad)
    end
  end

  example do
    pid.patient_identifier_lists.first.tap do |cx|
      identifier = gateway.cx_to_fhir_identifier(cx)
      identifier.use.should == 'usual'
      identifier.key.should == cx.id_number.to_p
      identifier.label.should == cx.id_number.to_p
      identifier.system.should == cx.identifier_type_code.to_p
    end
  end

  example do
    gender = gateway.pid_to_fhir_gender(pid)
    assert_gender(gender, pid.administrative_sex)
  end

  example do
    birth_date = gateway.pid_to_fhir_birth_date(pid)
    birth_date.should == DateTime.parse(pid.date_time_of_birth.time.to_p)
  end

  example do
    marital_status = gateway.pid_to_fhir_marital_status(pid)
    marital_status.codings.first.code.should == pid.marital_status.identifier.to_p
    marital_status.codings.first.display.should == gateway.marital_status_code_to_display(pid.marital_status.identifier.to_p)
    marital_status.text.should == gateway.marital_status_code_to_display(pid.marital_status.identifier.to_p)
  end

  example do
    pid.phone_number_homes.first.tap do |xtn|
      telecom = gateway.xtn_to_fhir_telecom(xtn, 'home')
      telecom.system.should == 'http://hl7.org/fhir/contact-system'
      telecom.value.should == xtn.telephone_number.to_p
      telecom.use.should == 'home'
    end
    pid.phone_number_businesses.first.tap do |xtn|
      telecom = gateway.xtn_to_fhir_telecom(xtn, 'work')
      telecom.system.should == 'http://hl7.org/fhir/contact-system'
      telecom.value.should == xtn.telephone_number.to_p
      telecom.use.should == 'work'
    end
  end

  example do
    deceased = gateway.pid_to_fhir_deceased(pid)
    deceased.should == DateTime.parse(pid.patient_death_date_and_time.time.to_p)
  end

  example do
    gateway.pid_to_fhir_multiple_birth(pid).should == pid.birth_order.to_p
  end

  example do
    nk1s.first.tap do |nk1|
      contact = gateway.nk1_to_fhir_contact(nk1)
      contact.relationships.first.tap do |cc|
        cc.codings.first.tap do |c|
          c.system.should == 'http://hl7.org/fhir/patient-contact-relationship'
          c.code.should == nk1.relationship.identifier.to_p
          c.display;
        end
        cc.codings.last.tap do |c|
          c.system.should == 'http://hl7.org/fhir/patient-contact-relationship'
          c.code.should == nk1.contact_role.identifier.to_p
          c.display;
        end
      end
      nk1.names.first.tap do |xpn|
        contact.name.tap do |n|
          n.families.first.should == xpn.family_name.surname.to_p
          n.givens.first.should == [xpn.given_name, xpn.second_and_further_given_names_or_initials_thereof].map(&:to_p).join(', ')
          n.prefixes.first.should == xpn.prefix.to_p
          n.suffixes.first.should == xpn.suffix.to_p
          n.text.should == (n.givens + n.families + n.prefixes + n.suffixes).join(' ')
          n.period.should be_nil
        end
      end
      nk1.phone_numbers.first.tap do |xtn|
        contact.telecoms.first.tap do |c|
          c.system.should == 'http://hl7.org/fhir/contact-system'
          c.value.should == xtn.telephone_number.to_p
          c.use.should == 'home'
          c.period.should be_nil
        end
      end
      nk1.business_phone_numbers.first.tap do |xtn|
        contact.telecoms.last.tap do |c|
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
    patient = gateway.message_to_fhir_patient(message)
    puts patient.to_yaml
  end

  example do
    encounter = gateway.message_to_fhir_encounter(message)
    puts encounter.to_yaml
  end

  example do
    patient_class = gateway.pv1_to_fhir_class(pv1)
    patient_class.should == pv1.patient_class.to_p
  end

  example do
    types = gateway.pv1_to_fhir_types(pv1)
    types.first.tap do |t|
      t.text.should == gateway.admission_type_code_to_display(pv1.admission_type.to_p)
      t.codings.first.tap do |c|
        c.system.should == 'http://hl7.org/fhir/v2/vs/0007'
        c.code.should == pv1.admission_type.to_p
        c.display.should == gateway.admission_type_code_to_display(pv1.admission_type.to_p)
      end
    end
  end

  example do
    identifiers = gateway.pv1_to_fhir_identifiers(pv1)
    identifiers.first.tap do |t|
      expect(t.key.should).to eq(pv1.visit_number.id_number.to_p)
      expect(t.label.should).to eq(pv1.visit_number.id_number.to_p)
      expect(t.system.should).to eq(pv1.visit_number.identifier_type_code.to_p)
    end
  end

  example do
    pre_admission_identifier = gateway.pv1_to_fhir_pre_admission_identifier(pv1)
    expect(pre_admission_identifier.key)
      .to eq(pv1.preadmit_number.id_number.to_p)
    expect(pre_admission_identifier.label)
      .to eq(pv1.preadmit_number.id_number.to_p)
    expect(pre_admission_identifier.system)
      .to eq(pv1.preadmit_number.identifier_type_code.to_p)
  end

  example do
    admit_source = gateway.pv1_to_admit_source(pv1)
    admit_source.first.tap do |t|
      fail 'need mapping'
    end
  end

  example do
    gateway.pv1_to_diet(pv1).tap do |diet|
      expect(diet.text).to eq(pv1.diet_type.text.to_p)
      diet.codings.first.tap do |primary|
        expect(primary.system).to eq(pv1.diet_type.name_of_coding_system.to_p)
        expect(primary.code).to eq(pv1.diet_type.identifier.to_p)
        expect(primary.display).to eq(pv1.diet_type.text.to_p)
      end
      diet.codings.second.tap do |primary|
        expect(primary.system).to eq(pv1.diet_type.name_of_alternate_coding_system.to_p)
        expect(primary.code).to eq(pv1.diet_type.alternate_identifier.to_p)
        expect(primary.display).to eq(pv1.diet_type.alternate_text.to_p)
      end
    end
  end

  example do
    gateway.pv1_to_fhir_special_courtesies(pv1).tap do |special_courtesies|
      expect(special_courtesies.text).to eq(pv1.vip_indicator.to_p)
      special_courtesies.codings.first.tap do |coding|
        expect(coding.code).to eq(pv1.vip_indicator.to_p)
        expect(coding.display).to eq(pv1.vip_indicator.to_p)
      end
    end
  end

  example do
    gateway.pv1_to_discharge_disposition(pv1).tap do |discharge_disposition|
      pv1_discharge_disposition = pv1.discharge_disposition.to_p

      expect(discharge_disposition.text).to eq(
        gateway.discharge_disposition_to_display(pv1_discharge_disposition))

      coding = discharge_disposition.codings.first
      expect(coding.system).to eq('http://hl7.org/fhir/discharge-disposition')
      expect(coding.code).to eq(
        gateway.discharge_disposition_to_code(pv1_discharge_disposition))

      expect(coding.display).to eq(
        gateway.discharge_disposition_to_display(pv1_discharge_disposition))
    end
  end

  example do
    gateway.pv1_to_admit_source(pv1).tap do |admit_source|
      pv1_admit_source = pv1.admit_source.to_p

      expect(admit_source.text).to eq(
        gateway.admit_source_to_display(pv1_admit_source))

      coding = admit_source.codings.first
      expect(coding.system).to eq('http://hl7.org/fhir/admit-source')
      expect(coding.code).to eq(
        gateway.admit_source_to_code(pv1_admit_source))

      expect(coding.display).to eq(
        gateway.admit_source_to_display(pv1_admit_source))
    end
  end

  example do
    gateway.pv1_to_fhir_re_admission(pv1).tap do |re_admission|
      expect(re_admission).to be_true
    end
  end

  example do
=begin
# Set ID - PV1
attribute :set_id_pv1, Si, position: "PV1.1"
# Assigned Patient Location
attribute :assigned_patient_location, Pl, position: "PV1.3"
# Prior Patient Location
attribute :prior_patient_location, Pl, position: "PV1.6"
# Attending Doctor
attribute :attending_doctors, Array[Xcn], position: "PV1.7", multiple: true
# Referring Doctor
attribute :referring_doctors, Array[Xcn], position: "PV1.8", multiple: true
# Consulting Doctor
attribute :consulting_doctors, Array[Xcn], position: "PV1.9", multiple: true
  # Hospital Service
  attribute :hospital_service, Is, position: "PV1.10"
  # Temporary Location
  attribute :temporary_location, Pl, position: "PV1.11"
  # Preadmit Test Indicator
  attribute :preadmit_test_indicator, Is, position: "PV1.12"
  # Re-admission Indicator
  attribute :re_admission_indicator, Is, position: "PV1.13"
  # Ambulatory Status
  attribute :ambulatory_statuses, Array[Is], position: "PV1.15", multiple: true
  # Admitting Doctor
  attribute :admitting_doctors, Array[Xcn], position: "PV1.17", multiple: true
  # Patient Type
  attribute :patient_type, Is, position: "PV1.18"
  # Financial Class
  attribute :financial_classes, Array[Fc], position: "PV1.20", multiple: true
  # Charge Price Indicator
  attribute :charge_price_indicator, Is, position: "PV1.21"
  # Courtesy Code
  attribute :courtesy_code, Is, position: "PV1.22"
  # Credit Rating
  attribute :credit_rating, Is, position: "PV1.23"
  # Contract Code
  attribute :contract_codes, Array[Is], position: "PV1.24", multiple: true
  # Contract Effective Date
  attribute :contract_effective_dates, Array[Dt], position: "PV1.25", multiple: true
  # Contract Amount
  attribute :contract_amounts, Array[Nm], position: "PV1.26", multiple: true
  # Contract Period
  attribute :contract_periods, Array[Nm], position: "PV1.27", multiple: true
  # Interest Code
  attribute :interest_code, Is, position: "PV1.28"
  # Transfer to Bad Debt Code
  attribute :transfer_to_bad_debt_code, Is, position: "PV1.29"
  # Transfer to Bad Debt Date
  attribute :transfer_to_bad_debt_date, Dt, position: "PV1.30"
  # Bad Debt Agency Code
  attribute :bad_debt_agency_code, Is, position: "PV1.31"
  # Bad Debt Transfer Amount
  attribute :bad_debt_transfer_amount, Nm, position: "PV1.32"
  # Bad Debt Recovery Amount
  attribute :bad_debt_recovery_amount, Nm, position: "PV1.33"
  # Delete Account Indicator
  attribute :delete_account_indicator, Is, position: "PV1.34"
  # Delete Account Date
  attribute :delete_account_date, Dt, position: "PV1.35"
  # Discharged to Location
  attribute :discharged_to_location, Dld, position: "PV1.37"
  # Servicing Facility
  attribute :servicing_facility, Is, position: "PV1.39"
  # Bed Status
  attribute :bed_status, Is, position: "PV1.40"
  # Account Status
  attribute :account_status, Is, position: "PV1.41"
  # Pending Location
  attribute :pending_location, Pl, position: "PV1.42"
  # Prior Temporary Location
  attribute :prior_temporary_location, Pl, position: "PV1.43"
  # Admit Date/Time
  attribute :admit_date_time, Ts, position: "PV1.44"
  # Discharge Date/Time
  attribute :discharge_date_times, Array[Ts], position: "PV1.45", multiple: true
  # Current Patient Balance
  attribute :current_patient_balance, Nm, position: "PV1.46"
  # Total Charges
  attribute :total_charges, Nm, position: "PV1.47"
  # Total Adjustments
  attribute :total_adjustments, Nm, position: "PV1.48"
  # Total Payments
  attribute :total_payments, Nm, position: "PV1.49"
  # Alternate Visit ID
  attribute :alternate_visit_id, Cx, position: "PV1.50"
  # Visit Indicator
  attribute :visit_indicator, Is, position: "PV1.51"
  # Other Healthcare Provider
  attribute :other_healthcare_providers, Array[Xcn], position: "PV1.52", multiple: true
=end
  end

  example do
    PatientAdministration::HL7Gateway::AdmitA01
    .new(config)
    .handle(message)

    pending

    pt = PatientAdministration::PatientUseCase
    .new(config)
    .find(identity)

    pt.should_not be_nil
  end

  def assert_address(address, xad)
    address.use.should == gateway.address_type_to_use(xad.address_type.to_p)
    address.text.should == [
      xad.street_address.try(:street_or_mailing_address),
      xad.street_address.try(:street_name),
      xad.street_address.try(:dwelling_number),
      xad.other_designation,
      xad.city,
      xad.state_or_province,
      xad.zip_or_postal_code,
      xad.country
    ].map(&:to_p).join(' ')
    address.lines.should == [
      xad.street_address.try(:street_or_mailing_address),
      xad.street_address.try(:street_name),
      xad.street_address.try(:dwelling_number),
      xad.other_designation
    ].map(&:to_p)
    address.city.should == xad.city.to_p
    address.state.should == xad.state_or_province.to_p
    address.zip.should == xad.zip_or_postal_code.to_p
    address.country.should == xad.country.to_p
    #address.period.start.should == DateTime.now
    #address.period.end.should == DateTime.now
    #:address_validity_range :effective_date :expiration_date
  end

  def assert_gender(gender, administrative_sex)
    gender.codings.first.tap do |c|
      c.code.should == administrative_sex.to_p
      c.display.should == gateway.gender_code_to_display(administrative_sex.to_p)
    end
  end
end
