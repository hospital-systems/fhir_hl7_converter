require 'spec_helper'
require 'health_seven'
require 'fhir'
require 'fhir_hl7_converter'
describe FhirHl7Converter::EncounterAttributeConverter do
  include HL7SpecHelper

  let(:subject)                              { FhirHl7Converter::EncounterAttributeConverter }
  let(:message)                              { fixture('adt_a01') }
  let(:hl7)                                  { HealthSeven::Message.parse(message) }
  let(:pv1)                                  { hl7.pv1 }
  let(:gateway)                              { FhirHl7Converter::Factory.hl7_to_fhir(hl7) }
  let(:terrminology)                         { gateway.terrminology }
  let(:discharge_disposition_v_s_identifier) { 'http://hl7.org/fhir/vs/encounter-discharge-disposition' }
  let(:admit_source_v_s_identifier)          { 'http://hl7.org/fhir/vs/encounter-admit-source' }
  let(:admission_type_v_s_identifier)        { 'http://hl7.org/fhir/v2/vs/0007' }

  example do
    patient_class = subject.fhir_class(hl7, gateway.terrminology)
    patient_class.should == pv1.patient_class.to_p
  end

  example do
    types = subject.fhir_types(hl7, gateway.terrminology)

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
    identifiers = subject.fhir_identifiers(hl7, gateway.terrminology)
    identifiers.first.tap do |t|
      expect(t.key.should).to eq(pv1.visit_number.id_number.to_p)
      expect(t.label.should).to eq(pv1.visit_number.id_number.to_p)
      expect(t.system.should).to eq(pv1.visit_number.identifier_type_code.to_p)
    end
  end

  example do
    pre_admission_identifier = subject.fhir_pre_admission_identifier(hl7, gateway.terrminology)
    expect(pre_admission_identifier.key)
    .to eq(pv1.preadmit_number.id_number.to_p)
    expect(pre_admission_identifier.label)
    .to eq(pv1.preadmit_number.id_number.to_p)
    expect(pre_admission_identifier.system)
    .to eq(pv1.preadmit_number.identifier_type_code.to_p)
  end

  example do
    admit_source = subject.pv1_to_admit_source(hl7, gateway.terrminology)
    admit_source.first.tap do |t|
      fail 'need mapping'
    end
  end

  example do
    subject.fhir_diet(hl7, gateway.terrminology).tap do |diet|
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
    subject.fhir_special_courtesies(hl7, gateway.terrminology).tap do |special_courtesies|
      expect(special_courtesies.text).to eq(pv1.vip_indicator.to_p)
      special_courtesies.codings.first.tap do |coding|
        expect(coding.code).to eq(pv1.vip_indicator.to_p)
        expect(coding.display).to eq(pv1.vip_indicator.to_p)
      end
    end
  end

  example do
    subject.fhir_discharge_disposition(hl7, gateway.terrminology).tap do |discharge_disposition|
      pv1_discharge_disposition = pv1.discharge_disposition.to_p

      external_coding = gateway.terrminology.coding(
          discharge_disposition_v_s_identifier,
          subject.discharge_disposition_to_code(pv1_discharge_disposition, gateway.terrminology))

      expect(discharge_disposition.text).to eq(external_coding[:display])

      coding = discharge_disposition.codings.first
      expect(coding.system).to eq(external_coding[:system])
      expect(coding.code).to   eq(external_coding[:code])

      expect(coding.display).to eq(external_coding[:display])
    end
  end

  example do
    subject.pv1_to_admit_source(hl7, gateway.terrminology).tap do |admit_source|
      pv1_admit_source = pv1.admit_source.to_p

      external_coding = gateway.terrminology.coding(
          admit_source_v_s_identifier,
          subject.admit_source_to_code(pv1_admit_source, gateway.terrminology)
      )

      expect(admit_source.text).to eq(external_coding[:display])

      coding = admit_source.codings.first
      expect(coding.system).to eq(external_coding[:system])
      expect(coding.code).to   eq(external_coding[:code])

      expect(coding.display).to eq(external_coding[:display])
    end
  end

  example do
    subject.fhir_re_admission(hl7, gateway.terrminology).tap do |re_admission|
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
    subject.fhir_location(hl7, gateway.terrminology).tap do |l|
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
    subject.fhir_reason(hl7, terrminology).should == hl7.pv2.admit_reason.text.to_p
  end

  example do
    puts hl7.pv2.visit_priority_code.to_yaml
    puts subject.fhir_priority(hl7, terrminology)
  end

  describe '#fhir_period' do
    it 'should convert hl7 admit_date_time and discharge_date_time into fhir period' do
      subject.fhir_period(hl7, terrminology).start.should == Time.parse(hl7.pv1.admit_date_time.time.to_p)
      subject.fhir_period(hl7, terrminology).end.should   == (hl7.pv1.discharge_date_times.blank? ? nil : Time.parse(hl7.pv1.discharge_date_times.first.time.to_p))
    end
  end
end
