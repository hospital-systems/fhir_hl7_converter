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
      subject.fhir_location(hl7, gateway.terrminology).tap do |bed|
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
