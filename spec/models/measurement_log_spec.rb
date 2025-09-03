require 'rails_helper'

RSpec.describe MeasurementLog, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:received_at) }
  end

  describe 'associations' do
    it { should belong_to(:run) }
    it { should belong_to(:measurement_point) }
  end

  describe 'scopes' do
    let(:flow) { create(:flow) }
    let(:run) { create(:run, flow: flow) }
    let(:measurement_point) { create(:measurement_point, flow: flow) }
    let!(:log1) { create(:measurement_log, run: run, measurement_point: measurement_point, received_at: 1.hour.ago) }
    let!(:log2) { create(:measurement_log, run: run, measurement_point: measurement_point, received_at: 30.minutes.ago) }

    it 'orders by received_at by default' do
      expect(MeasurementLog.all).to eq([log1, log2])
    end
  end

  describe 'timestamps' do
    let(:log) { create(:measurement_log) }

    it 'has timestamps' do
      expect(log.created_at).to be_present
      expect(log.updated_at).to be_present
    end
  end

  describe 'logs serialization' do
    let(:log_data) { { 'key' => 'value', 'nested' => { 'array' => [1, 2, 3] } } }
    let(:log) { create(:measurement_log, logs: log_data) }

    it 'serializes and deserializes logs as JSON' do
      expect(log.logs).to eq(log_data)
      expect(MeasurementLog.find(log.id).logs).to eq(log_data)
    end
  end

  describe 'validations' do
    let(:log) { build(:measurement_log) }

    it 'is valid with valid attributes' do
      expect(log).to be_valid
    end

    it 'is not valid without a run' do
      log.run = nil
      expect(log).not_to be_valid
    end

    it 'is not valid without a measurement point' do
      log.measurement_point = nil
      expect(log).not_to be_valid
    end

    it 'is not valid without a received_at timestamp' do
      log.received_at = nil
      expect(log).not_to be_valid
    end
  end
end
