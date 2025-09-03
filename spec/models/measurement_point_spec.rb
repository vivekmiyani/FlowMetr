# spec/models/measurement_point_spec.rb
require 'rails_helper'

RSpec.describe MeasurementPoint, type: :model do
  let(:flow) { create(:flow) }
  let!(:existing_point) { create(:measurement_point, flow: flow, node_id: 'node-1') }

  describe 'validations' do
    it { should validate_presence_of(:node_id) }
    it { should validate_inclusion_of(:node_type).in_array(%w[start stop checkpoint error]) }
    it { should validate_uniqueness_of(:node_id).scoped_to(:flow_id) }
  end

  describe 'associations' do
    it { should belong_to(:flow) }
    it { should have_many(:measurement_logs).dependent(:destroy) }
  end

  describe 'default values' do
    it 'sets a default name based on node_type and node_id' do
      point = build(:measurement_point, node_type: 'checkpoint', node_id: 'node-123', flow: flow)
      expect(point.name).to eq('Checkpoint node-123')
    end
  end
end