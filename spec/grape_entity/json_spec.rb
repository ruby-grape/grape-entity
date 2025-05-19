# frozen_string_literal: true

describe Grape::Entity::Json do
  subject { described_class }

  it { is_expected.to eq(JSON) }
end
