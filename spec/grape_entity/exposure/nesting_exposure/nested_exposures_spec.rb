require 'spec_helper'

describe Grape::Entity::Exposure::NestingExposure::NestedExposures do
  subject(:nested_exposures) { described_class.new([]) }

  describe '#deep_complex_nesting?' do
    it 'is reset when additional exposure is added' do
      subject << Grape::Entity::Exposure.new(:x, {})
      expect(subject.instance_variable_get(:@deep_complex_nesting)).to be_nil
      subject.deep_complex_nesting?
      expect(subject.instance_variable_get(:@deep_complex_nesting)).to_not be_nil
      subject << Grape::Entity::Exposure.new(:y, {})
      expect(subject.instance_variable_get(:@deep_complex_nesting)).to be_nil
    end

    it 'is reset when exposure is deleted' do
      subject << Grape::Entity::Exposure.new(:x, {})
      expect(subject.instance_variable_get(:@deep_complex_nesting)).to be_nil
      subject.deep_complex_nesting?
      expect(subject.instance_variable_get(:@deep_complex_nesting)).to_not be_nil
      subject.delete_by(:x)
      expect(subject.instance_variable_get(:@deep_complex_nesting)).to be_nil
    end

    it 'is reset when exposures are cleared' do
      subject << Grape::Entity::Exposure.new(:x, {})
      expect(subject.instance_variable_get(:@deep_complex_nesting)).to be_nil
      subject.deep_complex_nesting?
      expect(subject.instance_variable_get(:@deep_complex_nesting)).to_not be_nil
      subject.clear
      expect(subject.instance_variable_get(:@deep_complex_nesting)).to be_nil
    end
  end

  describe '.delete_by' do
    subject { nested_exposures.delete_by(*attributes) }

    let(:attributes) { [:id] }

    before do
      nested_exposures << Grape::Entity::Exposure.new(:id, {})
    end

    it 'deletes matching exposure' do
      is_expected.to eq []
    end

    context "when given attribute doesn't exists" do
      let(:attributes) { [:foo] }

      it 'deletes matching exposure' do
        is_expected.to eq(nested_exposures)
      end
    end
  end
end
