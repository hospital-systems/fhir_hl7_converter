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
  let(:discharge_disposition_v_s_identifier) { 'http://hl7.org/fhir/vs/encounter-discharge-disposition' }
  let(:admit_source_v_s_identifier)          { 'http://hl7.org/fhir/vs/encounter-admit-source' }
  let(:admission_type_v_s_identifier)        { 'http://hl7.org/fhir/v2/vs/0007' }

  example do
    patient_class = subject.fhir_class(hl7)
    patient_class.should == pv1.patient_class.to_p
  end

  describe '#fhir_types' do
    it 'should create codeable concept containing admission_type from hl7 message' do
      types = subject.fhir_types(hl7)

      types.first.tap do |t|
        t.text.should == hl7.pv1.admission_type.try(:to_p)
        t.coding.first.tap do |c|
          c.system.should  == admission_type_v_s_identifier
          c.code.should    == hl7.pv1.admission_type.try(:to_p)
          c.display.should == hl7.pv1.admission_type.try(:to_p)
        end
      end
    end
  end

  describe '#fhir_identifiers' do
    it 'should create fhir identifier from hl7 pv1 visit_number' do
      identifiers = subject.fhir_identifiers(hl7)
      identifiers.first.tap do |t|
        expect(t.value).to  eq(hl7.pv1.visit_number.id_number.to_p)
        expect(t.label).to  eq(hl7.pv1.visit_number.id_number.to_p)
        expect(t.system).to eq(hl7.pv1.visit_number.identifier_type_code.to_p)
      end
    end
  end

  describe '#fhir_pre_admission_identifier' do
    it 'should create fhir identifier from hl7 pv1 preadmit_number' do
      pre_admission_identifier = subject.fhir_pre_admission_identifier(hl7)
      expect(pre_admission_identifier.value).to  eq(hl7.pv1.preadmit_number.id_number.to_p)
      expect(pre_admission_identifier.label).to  eq(hl7.pv1.preadmit_number.id_number.to_p)
      expect(pre_admission_identifier.system).to eq(hl7.pv1.preadmit_number.identifier_type_code.to_p)
    end
  end

  describe '#fhir_admit_source' do
    it 'should create codeable concept containing admit_source from hl7 message' do
      subject.fhir_admit_source(hl7).tap do |admit_source|
        expect(admit_source.text).to eq(hl7.pv1.admit_source.try(:to_p))
        coding = admit_source.coding.first
        expect(coding.code).to    eq(hl7.pv1.admit_source.try(:to_p))
        expect(coding.display).to eq(hl7.pv1.admit_source.try(:to_p))
      end
    end
  end

  example do
    subject.fhir_diet(hl7).tap do |diet|
      expect(diet.text).to eq(pv1.diet_type.text.to_p)
      diet.coding.first.tap do |primary|
        expect(primary.system).to eq(pv1.diet_type.name_of_coding_system.to_p)
        expect(primary.code).to eq(pv1.diet_type.identifier.to_p)
        expect(primary.display).to eq(pv1.diet_type.text.to_p)
      end
      diet.coding.second.tap do |primary|
        expect(primary.system).to eq(pv1.diet_type.name_of_alternate_coding_system.to_p)
        expect(primary.code).to eq(pv1.diet_type.alternate_identifier.to_p)
        expect(primary.display).to eq(pv1.diet_type.alternate_text.to_p)
      end
    end
  end

  example do
    subject.fhir_special_courtesies(hl7).tap do |special_courtesies|
      expect(special_courtesies.text).to eq(pv1.vip_indicator.to_p)
      special_courtesies.coding.first.tap do |coding|
        expect(coding.code).to eq(pv1.vip_indicator.to_p)
        expect(coding.display).to eq(pv1.vip_indicator.to_p)
      end
    end
  end

  describe '#fhir_discharge_disposition' do
    it 'should create codeable concept containing discharge_disposition from hl7 message' do
      subject.fhir_discharge_disposition(hl7).tap do |discharge_disposition|
        expect(discharge_disposition.text).to eq(hl7.pv1.discharge_disposition.try(:to_p))
        coding = discharge_disposition.coding.first
        expect(coding.code).to   eq(hl7.pv1.discharge_disposition.try(:to_p))
        expect(coding.display).to eq(hl7.pv1.discharge_disposition.try(:to_p))
      end
    end
  end

  describe '#fhir_admit_source' do
    it 'should create codeable concept containing admit_source from hl7 message' do
      subject.fhir_admit_source(hl7).tap do |admit_source|
        expect(admit_source.text).to eq(hl7.pv1.admit_source.try(:to_p))
        coding = admit_source.coding.first
        expect(coding.code).to    eq(hl7.pv1.admit_source.try(:to_p))
        expect(coding.display).to eq(hl7.pv1.admit_source.try(:to_p))
      end
    end
  end

  example do
    subject.fhir_re_admission(hl7).tap do |re_admission|
      expect(re_admission).to be_true
    end
  end

  example do
    pv1.assigned_patient_location.tap do |l|
      subject.fhir_location(hl7).tap do |bed|
        bed.name.should == l.bed.to_p
        bed.description.should == l.bed.to_p
        #bed.mode.should == 'instance'
        #bed.status.should == 'active'
        bed.part_of.tap do |room|
          room.name.should == l.room.to_p
          room.description.should == l.room.to_p
          #room.mode.should == 'kind'
          #room.status.should == 'active'
          room.part_of.tap do |point_of_care|
            point_of_care.name.should == l.point_of_care.to_p
            point_of_care.description.should == l.point_of_care.to_p
            #point_of_care.mode.should == 'kind'
            #point_of_care.status.should == 'active'
            point_of_care.part_of.tap do |facility|
              facility.name.should == l.facility.namespace_id.to_p
              facility.description.should == l.facility.namespace_id.to_p
              #facility.mode.should == 'kind'
              #facility.status.should == 'active'
            end
          end
        end
      end
    end
  end

  describe '#fhir_reason' do
    it 'should create codeable concept containing reason from hl7 message' do
      subject.fhir_reason(hl7).coding.first.code.should == hl7.pv2.admit_reason.text.to_p
    end
  end

  example do
    puts hl7.pv2.visit_priority_code.to_yaml
    puts subject.fhir_priority(hl7)
  end

  describe '#fhir_period' do
    it 'should convert hl7 admit_date_time and discharge_date_time into fhir period' do
      subject.fhir_period(hl7).start.should == Time.parse(hl7.pv1.admit_date_time.time.to_p)
      subject.fhir_period(hl7).end.should == (hl7.pv1.discharge_date_times.blank? ? nil : Time.parse(hl7.pv1.discharge_date_times.first.time.to_p))
    end
  end
end
