require 'rails_helper'

RSpec.describe WebhookProcessorJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:flow) { create(:flow, project: project, webhook_token: 'test_token') }
  let(:run_id) { SecureRandom.uuid }
  let(:current_time) { Time.current }

  around do |example|
    travel_to current_time do
      example.run
    end
  end

  describe '#perform' do
    context 'with a start trigger' do
      let(:params) do
        {
          "node_id" => "start_1",
          "node_type" => "start",
          "run_id" => run_id,
          "logs" => "Workflow started"
        }
      end

      it 'creates a new run' do
        expect {
          described_class.perform_now(flow.webhook_token, params, current_time.iso8601, project.secret_token)
        }.to change(Run, :count).by(1)
      end

      it 'creates a measurement log' do
        expect {
          described_class.perform_now(flow.webhook_token, params, current_time.iso8601, project.secret_token)
        }.to change(MeasurementLog, :count).by(1)
      end

      it 'sets the run status to pending' do
        described_class.perform_now(flow.webhook_token, params, current_time.iso8601, project.secret_token)
        expect(Run.last).to be_pending
      end
    end

    context 'with a stop trigger' do
      let!(:run) { create(:run, flow: flow, uuid: run_id, status: :pending, started_at: 1.hour.ago) }
      let(:params) do
        {
          "node_id" => "stop_1",
          "node_type" => "stop",
          "run_id" => run_id,
          "logs" => "Workflow completed"
        }
      end

      it 'completes the run' do
        expect {
          described_class.perform_now(flow.webhook_token, params, current_time.iso8601, project.secret_token)
          run.reload
        }.to change(run, :status).from('pending').to('successful')
      end

      it 'creates a measurement log' do
        expect {
          described_class.perform_now(flow.webhook_token, params, current_time.iso8601, project.secret_token)
        }.to change(MeasurementLog, :count).by(1)
      end

      it 'sets the end time and duration' do
        described_class.perform_now(flow.webhook_token, params, current_time.iso8601, project.secret_token)
        run.reload
        expect(run.ended_at).to be_within(1.second).of(current_time)
        expect(run.duration).to be_within(1).of(3600) # 1 hour in seconds
      end
    end

    context 'with a stop trigger for a completed run' do
      let!(:run) { create(:run, :completed, flow: flow, uuid: run_id) }
      let(:params) do
        {
          "node_id" => "stop_1",
          "node_type" => "stop",
          "run_id" => run_id,
          "logs" => "Duplicate stop trigger"
        }
      end

      it 'does not create a measurement log' do
        expect {
          described_class.perform_now(flow.webhook_token, params, current_time.iso8601, project.secret_token)
        }.not_to change(MeasurementLog, :count)
      end
    end

    context 'with an error trigger' do
      let!(:run) { create(:run, flow: flow, uuid: run_id, status: :pending) }
      let(:params) do
        {
          "node_id" => "error_1",
          "node_type" => "error",
          "run_id" => run_id,
          "logs" => "Something went wrong"
        }
      end

      it 'marks the run as failed' do
        expect {
          described_class.perform_now(flow.webhook_token, params, current_time.iso8601, project.secret_token)
          run.reload
        }.to change(run, :status).from('pending').to('failed')
      end

      it 'creates a measurement log' do
        expect {
          described_class.perform_now(flow.webhook_token, params, current_time.iso8601, project.secret_token)
        }.to change(MeasurementLog, :count).by(1)
      end
    end

    context 'with a checkpoint trigger' do
      let!(:run) { create(:run, flow: flow, uuid: run_id, status: :pending) }
      let(:params) do
        {
          "node_id" => "checkpoint_1",
          "node_type" => "checkpoint",
          "run_id" => run_id,
          "logs" => "Reached checkpoint"
        }
      end

      it 'creates a measurement log' do
        expect {
          described_class.perform_now(flow.webhook_token, params, current_time.iso8601, project.secret_token)
        }.to change(MeasurementLog, :count).by(1)
      end

      it 'does not change the run status' do
        expect {
          described_class.perform_now(flow.webhook_token, params, current_time.iso8601, project.secret_token)
          run.reload
        }.not_to change(run, :status)
      end
    end

    context 'with an invalid flow token' do
      let(:params) { { "node_id" => "start_1", "node_type" => "start" } }

      it 'raises an error' do
        expect {
          described_class.perform_now('invalid_token', params, current_time.iso8601, project.secret_token)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with a stop trigger and no active run' do
      let(:params) do
        {
          "node_id" => "stop_1",
          "node_type" => "stop",
          "run_id" => run_id
        }
      end

      it 'raises an error' do
        expect {
          described_class.perform_now(flow.webhook_token, params, current_time.iso8601, project.secret_token)
        }.to raise_error(ActiveRecord::RecordNotFound, /No run found with UUID: #{run_id}/)
      end
    end
  end
end
