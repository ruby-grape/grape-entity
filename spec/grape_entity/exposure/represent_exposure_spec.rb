# frozen_string_literal: true

require 'spec_helper'

describe Grape::Entity::Exposure::RepresentExposure do
  subject(:exposure) { described_class.new(:foo, {}, {}, double, double) }

  describe '#setup' do
    subject { exposure.setup(using_class_name, subexposure) }

    let(:using_class_name) { double(:using_class_name) }
    let(:subexposure)      { double(:subexposure) }

    it 'sets using_class_name' do
      expect { subject }.to change { exposure.using_class_name }.to(using_class_name)
    end

    it 'sets subexposure' do
      expect { subject }.to change { exposure.subexposure }.to(subexposure)
    end

    context 'when using_class is set' do
      before do
        exposure.using_class
      end

      it 'resets using_class' do
        expect { subject }.to change { exposure.using_class }
      end
    end
  end
end
