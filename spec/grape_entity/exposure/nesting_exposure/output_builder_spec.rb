# frozen_string_literal: true

require 'spec_helper'

describe Grape::Entity::Exposure::NestingExposure::OutputBuilder do
  subject(:builder) { described_class.new(Object.new) }

  let(:merged_array) { double(for_merge: true) }
  let(:plain) { double(for_merge: false, key: :name) }

  it 'returns the same result when #output is called repeatedly' do
    builder.add(merged_array, %w[a b])
    builder.add(plain, 'John')

    expected = ['a', 'b', { name: 'John' }]
    2.times { expect(builder.output).to eq(expected) }
  end
end
