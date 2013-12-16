require 'spec_helper'
require 'health_seven'
require 'fhir'
require 'fhir_hl7_converter'
describe 'PatientAdministration' do
  include HL7SpecHelper

  let(:message) { fixture('adt_a01') }
  let(:hl7) { HealthSeven::Message.parse(message) }
  let(:gateway) { FhirHl7Converter::Factory.hl7_to_fhir(hl7) }
  let(:pid) { hl7.pid }
  let(:nk1s) { hl7.nk1s }
  let(:pv1) { hl7.pv1 }
  let(:discharge_disposition_v_s_identifier) { 'http://hl7.org/fhir/vs/encounter-discharge-disposition' }
  let(:admit_source_v_s_identifier)          { 'http://hl7.org/fhir/vs/encounter-admit-source' }
  let(:administrative_sex_v_s_identifier)    { 'http://hl7.org/fhir/vs/administrative-gender' }
  let(:marital_status_code_v_s_identifier)   { 'http://hl7.org/fhir/vs/marital-status' }
  let(:admission_type_v_s_identifier)        { 'http://hl7.org/fhir/v2/vs/0007' }

  before(:all) do
    #gateway = FhirHl7Converter::Factory.hl7_to_fhir(HealthSeven::Message.parse(fixture('adt_a01')))
    #gateway.terrminology.initialize_data
  end

  example do
    pid.patient_names.first.tap do |xpn|
      name = FhirHl7Converter::DataTypeConverter.xpn_to_fhir_name(xpn)
      name.families.first.should == xpn.family_name.surname.to_p
      name.givens.first.should == [xpn.given_name, xpn.second_and_further_given_names_or_initials_thereof].map(&:to_p).join(', ')
      name.prefixes.first.should == xpn.prefix.to_p
      name.suffixes.first.should == xpn.suffix.to_p
      name.text.should == (name.givens + name.families + name.prefixes + name.suffixes).join(' ')
    end
  end

  example do
    pid.patient_addresses.first.tap do |xad|
      address = FhirHl7Converter::DataTypeConverter.xad_to_fhir_address(xad, gateway.terrminology)
      assert_address(address, xad)
    end
  end

  example do
    pid.patient_identifier_lists.first.tap do |cx|
      identifier = FhirHl7Converter::DataTypeConverter.cx_to_fhir_identifier(cx)
      identifier.use.should == 'usual'
      identifier.key.should == cx.id_number.to_p
      identifier.label.should == cx.id_number.to_p
      identifier.system.should == cx.identifier_type_code.to_p
    end
  end

  example do
    gender = FhirHl7Converter::PatientAttributeConverter.fhir_gender(hl7, gateway.terrminology)
    assert_gender(gender, pid.administrative_sex)
  end

  example do
    birth_date = FhirHl7Converter::PatientAttributeConverter.fhir_birth_date(hl7, gateway.terrminology)
    birth_date.should == DateTime.parse(pid.date_time_of_birth.time.to_p)
  end

  example do
    coding = gateway.terrminology.coding(
      marital_status_code_v_s_identifier,
      pid.marital_status.identifier.to_p)

      marital_status = FhirHl7Converter::PatientAttributeConverter.fhir_marital_status(hl7, gateway.terrminology)

      marital_status.codings.first.code.should    == coding[:code]
      marital_status.codings.first.display.should == coding[:display]
      marital_status.text.should                  == coding[:display]
  end

  example do
    pid.phone_number_homes.first.tap do |xtn|
      telecom = FhirHl7Converter::DataTypeConverter.xtn_to_fhir_telecom(xtn, 'home')
      telecom.system.should == 'http://hl7.org/fhir/contact-system'
      telecom.value.should == xtn.telephone_number.to_p
      telecom.use.should == 'home'
    end
    pid.phone_number_businesses.first.tap do |xtn|
      telecom = FhirHl7Converter::DataTypeConverter.xtn_to_fhir_telecom(xtn, 'work')
      telecom.system.should == 'http://hl7.org/fhir/contact-system'
      telecom.value.should == xtn.telephone_number.to_p
      telecom.use.should == 'work'
    end
  end

  example do
    deceased = FhirHl7Converter::PatientAttributeConverter.fhir_deceased(hl7, gateway.terrminology)
    deceased.should == DateTime.parse(pid.patient_death_date_and_time.time.to_p)
  end

  example do
    FhirHl7Converter::PatientAttributeConverter.fhir_multiple_birth(hl7, gateway.terrminology).should == pid.birth_order.to_p
  end

  example do
    nk1s.first.tap do |nk1|
      contact = FhirHl7Converter::PatientAttributeConverter.nk1_to_fhir_contact(nk1, gateway.terrminology)
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
    patient = gateway.patient
    puts patient.to_yaml
  end

  example do
    encounter = gateway.encounter
    puts encounter.to_yaml
  end

  example do
    patient_class = FhirHl7Converter::EncounterAttributeConverter.fhir_class(hl7, gateway.terrminology)
    patient_class.should == pv1.patient_class.to_p
  end

  example do
    types = FhirHl7Converter::EncounterAttributeConverter.fhir_types(hl7, gateway.terrminology)

    coding = gateway.terrminology.coding(
      admission_type_v_s_identifier,
      pv1.admission_type.to_p
    )

    types.first.tap do |t|
      t.text.should == coding[:display]
      t.codings.first.tap do |c|
        c.system.should  == coding[:system]
        c.code.should    == coding[:code]
        c.display.should == coding[:display]
      end
    end
  end

  example do
    identifiers = FhirHl7Converter::EncounterAttributeConverter.fhir_identifiers(hl7, gateway.terrminology)
    identifiers.first.tap do |t|
      expect(t.key.should).to eq(pv1.visit_number.id_number.to_p)
      expect(t.label.should).to eq(pv1.visit_number.id_number.to_p)
      expect(t.system.should).to eq(pv1.visit_number.identifier_type_code.to_p)
    end
  end

  example do
    pre_admission_identifier = FhirHl7Converter::EncounterAttributeConverter.fhir_pre_admission_identifier(hl7, gateway.terrminology)
    expect(pre_admission_identifier.key)
    .to eq(pv1.preadmit_number.id_number.to_p)
    expect(pre_admission_identifier.label)
    .to eq(pv1.preadmit_number.id_number.to_p)
    expect(pre_admission_identifier.system)
    .to eq(pv1.preadmit_number.identifier_type_code.to_p)
  end

  example do
    admit_source = FhirHl7Converter::EncounterAttributeConverter.pv1_to_admit_source(hl7, gateway.terrminology)
    admit_source.first.tap do |t|
      fail 'need mapping'
    end
  end

  example do
    FhirHl7Converter::EncounterAttributeConverter.fhir_diet(hl7, gateway.terrminology).tap do |diet|
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
    FhirHl7Converter::EncounterAttributeConverter.fhir_special_courtesies(hl7, gateway.terrminology).tap do |special_courtesies|
      expect(special_courtesies.text).to eq(pv1.vip_indicator.to_p)
      special_courtesies.codings.first.tap do |coding|
        expect(coding.code).to eq(pv1.vip_indicator.to_p)
        expect(coding.display).to eq(pv1.vip_indicator.to_p)
      end
    end
  end

  example do
    FhirHl7Converter::EncounterAttributeConverter.fhir_discharge_disposition(hl7, gateway.terrminology).tap do |discharge_disposition|
      pv1_discharge_disposition = pv1.discharge_disposition.to_p

      external_coding = gateway.terrminology.coding(
        discharge_disposition_v_s_identifier,
        FhirHl7Converter::EncounterAttributeConverter.discharge_disposition_to_code(pv1_discharge_disposition, gateway.terrminology))

        expect(discharge_disposition.text).to eq(external_coding[:display])

        coding = discharge_disposition.codings.first
        expect(coding.system).to eq(external_coding[:system])
        expect(coding.code).to   eq(external_coding[:code])

        expect(coding.display).to eq(external_coding[:display])
    end
  end

  example do
    FhirHl7Converter::EncounterAttributeConverter.pv1_to_admit_source(hl7, gateway.terrminology).tap do |admit_source|
      pv1_admit_source = pv1.admit_source.to_p

      external_coding = gateway.terrminology.coding(
        admit_source_v_s_identifier,
        FhirHl7Converter::EncounterAttributeConverter.admit_source_to_code(pv1_admit_source, gateway.terrminology)
      )

      expect(admit_source.text).to eq(external_coding[:display])

      coding = admit_source.codings.first
      expect(coding.system).to eq(external_coding[:system])
      expect(coding.code).to   eq(external_coding[:code])

      expect(coding.display).to eq(external_coding[:display])
    end
  end

  example do
    FhirHl7Converter::EncounterAttributeConverter.fhir_re_admission(hl7, gateway.terrminology).tap do |re_admission|
      expect(re_admission).to be_true
    end
  end

  example do
    pv1.assigned_patient_location.tap do |l|
      puts l.point_of_care.to_p
      puts l.room.to_p
      puts l.bed.to_p
      l.facility.tap do |f|
        puts f.namespace_id.to_p
      end
    end
    puts pv1.prior_patient_location.to_yaml#, Pl, position: "PV1.6"
    puts pv1.temporary_location.to_yaml#, Pl, position: "PV1.11"
    puts pv1.pending_location.to_yaml#, Pl, position: "PV1.42"
    puts pv1.prior_temporary_location.to_yaml#, Pl, position: "PV1.43"
    FhirHl7Converter::EncounterAttributeConverter.fhir_location(hl7, gateway.terrminology).tap do |l|
      l.text#, Fhir::Narrative
      l.name#, String
      l.description#, String
      l.types#, Array[Fhir::CodeableConcept]
      l.telecom#, Fhir::Contact
      l.address#, Fhir::Address
      l.position.tap do |p|#, Position
        p.longitude#, Float
        p.latitude#, Float
        p.altitude#, Float
      end
      l.provider#, [Fhir::Organization]
      l.active#, Boolean
      l.part_of#, [Fhir::Location]
    end
=begin
class Pl < ::HealthSeven::DataType
  # Point of Care
  attribute :point_of_care, Is, position: "PL.1"
  # Room
  attribute :room, Is, position: "PL.2"
  # Bed
  attribute :bed, Is, position: "PL.3"
  # Facility
  attribute :facility, Hd, position: "PL.4"
  # Location Status
  attribute :location_status, Is, position: "PL.5"
  # Person Location Type
  attribute :person_location_type, Is, position: "PL.6"
  # Building
  attribute :building, Is, position: "PL.7"
  # Floor
  attribute :floor, Is, position: "PL.8"
  # Location Description
  attribute :location_description, St, position: "PL.9"
  # Comprehensive Location Identifier
  attribute :comprehensive_location_identifier, Ei, position: "PL.10"
  # Assigning Authority for Location
  attribute :assigning_authority_for_location, Hd, position: "PL.11"
end
    end
  end

  example do
=begin
# Set ID - PV1
attribute :set_id_pv1, Si, position: "PV1.1"
# Prior Patient Location
attribute :prior_patient_location, Pl, position: "PV1.6"
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

  example do
    puts pv1.attending_doctors.to_yaml#, Array[Xcn], position: "PV1.7", multiple: true
    puts pv1.referring_doctors.to_yaml#, Array[Xcn], position: "PV1.8", multiple: true
    puts pv1.consulting_doctors.to_yaml#, Array[Xcn], position: "PV1.9", multiple: true
    puts pv1.admitting_doctors.to_yaml#, Array[Xcn], position: "PV1.17", multiple: true
    pv1.attending_doctors.first.tap do |xcn|
      FhirHl7Converter::DataTypeConverter.xcn_to_fhir_practitioner(xcn).tap do |p|
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

  def assert_address(address, xad)
    address.use.should == FhirHl7Converter::DataTypeConverter.address_type_to_use(xad.address_type.to_p, gateway.terrminology)
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
    coding = gateway.terrminology.coding(
      administrative_sex_v_s_identifier,
      administrative_sex.to_p)
      gender.codings.first.tap do |c|
        c.code.should    == coding[:code]
        c.display.should == coding[:display]
      end
  end
end
