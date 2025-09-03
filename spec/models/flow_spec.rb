require 'rails_helper'

RSpec.describe Flow, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'associations' do
    it 'has one start point' do
      association = described_class.reflect_on_association(:start_point)
      expect(association.macro).to eq :has_one
      expect(association.options).to include(class_name: 'MeasurementPoint')
      
      flow = create(:flow)
      start_point = create(:measurement_point, flow: flow, node_type: 'start')
      other_type = create(:measurement_point, flow: flow, node_type: 'checkpoint')
      
      expect(flow.start_point).to eq(start_point)
    end
    
    it 'has one end point' do
      association = described_class.reflect_on_association(:end_point)
      expect(association.macro).to eq :has_one
      expect(association.options).to include(class_name: 'MeasurementPoint')
      
      flow = create(:flow)
      end_point = create(:measurement_point, flow: flow, node_type: 'stop')
      other_type = create(:measurement_point, flow: flow, node_type: 'checkpoint')
      
      expect(flow.end_point).to eq(end_point)
    end
    
    it 'has many checkpoints' do
      association = described_class.reflect_on_association(:checkpoints)
      expect(association.macro).to eq :has_many
      expect(association.options).to include(class_name: 'MeasurementPoint')
      
      flow = create(:flow)
      checkpoint = create(:measurement_point, flow: flow, node_type: 'checkpoint')
      other_type = create(:measurement_point, flow: flow, node_type: 'stop')
      
      expect(flow.checkpoints).to include(checkpoint)
      expect(flow.checkpoints).not_to include(other_type)
    end
    
    it 'has many error points' do
      association = described_class.reflect_on_association(:error_points)
      expect(association.macro).to eq :has_many
      expect(association.options).to include(class_name: 'MeasurementPoint')
      
      flow = create(:flow)
      error_point = create(:measurement_point, flow: flow, node_type: 'error')
      other_type = create(:measurement_point, flow: flow, node_type: 'checkpoint')
      
      expect(flow.error_points).to include(error_point)
      expect(flow.error_points).not_to include(other_type)
    end
    
    it { should belong_to(:user) }
    it { should belong_to(:project).optional }
    it { should have_many(:runs).dependent(:destroy) }
    it { should have_many(:measurement_points).dependent(:destroy) }
  end

  describe 'callbacks' do
    let(:flow) { build(:flow, webhook_token: nil) }

    it 'generates a webhook token before create' do
      expect(flow.webhook_token).to be_nil
      flow.save!
      expect(flow.webhook_token).to be_present
      expect(flow.webhook_token).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
    end
  end

  describe '#webhook_url' do
    let(:project) { create(:project) }
    let(:flow) { create(:flow, project: project) }
    let(:expected_url) { "#{ENV['HOST_URL']}/webhooks/receive?token=#{flow.webhook_token}&project_token=#{project.secret_token}" }

    before do
      # Stub the webhook token generation to use a predictable value for testing
      allow(SecureRandom).to receive(:uuid).and_return('test-token')
    end

    it 'returns the correct webhook URL' do
      expect(flow.webhook_url).to eq(expected_url)
    end

    context 'when webhook_token is missing' do
      before { flow.update!(webhook_token: nil) }
      
      it 'returns nil' do
        expect(flow.webhook_url).to be_nil
      end
    end

    context 'when project is missing' do
      before { flow.update!(project: nil) }
      
      it 'returns nil' do
        expect(flow.webhook_url).to be_nil
      end
    end
  end

  describe '#latest_duration' do
    let(:flow) { create(:flow) }
    
    it 'returns the duration of the most recent run' do
      create(:run, flow: flow, started_at: 1.hour.ago, ended_at: Time.current, duration: 3600)
      create(:run, flow: flow, started_at: 2.hours.ago, ended_at: 1.hour.ago, duration: 1800)
      
      expect(flow.latest_duration).to eq(3600)
    end

    it 'returns nil if no runs exist' do
      expect(flow.latest_duration).to be_nil
    end
  end

  describe 'run status methods' do
    let(:flow) { create(:flow) }
    
    describe '#successful_run?' do
      it 'returns true if there are successful runs' do
        create(:run, :completed, flow: flow, status: 'successful')
        expect(flow).to be_successful_run
      end

      it 'returns false if there are no successful runs' do
        expect(flow).not_to be_successful_run
      end
    end

    describe '#pending_run?' do
      it 'returns true if there are pending runs' do
        create(:run, flow: flow, status: 'pending')
        expect(flow).to be_pending_run
      end

      it 'returns false if there are no pending runs' do
        expect(flow).not_to be_pending_run
      end
    end

    describe '#failed_run?' do
      it 'returns true if there are failed runs' do
        create(:run, :completed, flow: flow, status: 'failed', error: true)
        expect(flow).to be_failed_run
      end

      it 'returns false if there are no failed runs' do
        expect(flow).not_to be_failed_run
      end
    end
  end

  describe '#last_run_checkpoint_durations' do
    let(:flow) { create(:flow) }
    let(:run) { create(:run, flow: flow, started_at: 1.hour.ago, ended_at: Time.current, status: 'successful') }
    let!(:start_point) { create(:measurement_point, flow: flow, node_type: 'start', node_id: 'start_1', name: 'Start') }
    let!(:checkpoint1) { create(:measurement_point, flow: flow, node_type: 'checkpoint', node_id: 'check_1', name: 'Check 1') }
    let!(:checkpoint2) { create(:measurement_point, flow: flow, node_type: 'checkpoint', node_id: 'check_2', name: 'Check 2') }
    let!(:end_point) { create(:measurement_point, flow: flow, node_type: 'stop', node_id: 'stop_1', name: 'End') }

    before do
      create(:measurement_log, run: run, measurement_point: start_point, received_at: 1.hour.ago)
      create(:measurement_log, run: run, measurement_point: checkpoint1, received_at: 45.minutes.ago)
      create(:measurement_log, run: run, measurement_point: checkpoint2, received_at: 30.minutes.ago)
      create(:measurement_log, run: run, measurement_point: end_point, received_at: Time.current)
    end

    it 'returns an empty array if no runs exist' do
      flow.runs.destroy_all
      expect(flow.last_run_checkpoint_durations).to eq([])
    end
  end
end
