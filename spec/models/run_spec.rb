require 'rails_helper'

RSpec.describe Run, type: :model do
  describe 'enums' do
    it { should define_enum_for(:status).with_values(pending: 'pending', successful: 'successful', failed: 'failed').backed_by_column_of_type(:string) }
  end

  describe 'associations' do
    it { should belong_to(:flow) }
    it { should have_many(:measurement_logs).dependent(:destroy) }
  end

  describe 'callbacks' do
    let(:run) { build(:run, uuid: nil) }

    it 'generates a UUID before create' do
      expect(run.uuid).to be_nil
      run.save!
      expect(run.uuid).to be_present
      expect(run.uuid).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:flow) { create(:flow, user: user) }
    let!(:run1) { create(:run, flow: flow, status: :pending) }
    let!(:run2) { create(:run, :completed, flow: flow, status: :successful) }
    let!(:run3) { create(:run, :completed, flow: flow, status: :failed, error: true) }
    let!(:other_flow_run) { create(:run, status: :pending) }

    describe '.by_user' do
      it 'returns runs for the specified user' do
        runs = described_class.by_user(user)
        expect(runs).to include(run1, run2, run3)
        expect(runs).not_to include(other_flow_run)
      end
    end
  end

  describe '#complete!' do
    let(:start_time) { 1.hour.ago }
    let(:end_time) { Time.current }
    let(:run) { create(:run, started_at: start_time, status: :pending) }

    context 'when the run is not in error state' do
      it 'updates the run as successful' do
        expect {
          run.complete!(end_time)
          run.reload
        }.to change(run, :status).from('pending').to('successful')
         .and change(run, :ended_at).to(be_within(1.second).of(end_time))
         .and change(run, :duration).to(be_within(1).of(3600)) # 1 hour in seconds
         .and change(run, :error).to(false)
      end
    end

    context 'when the run is in error state' do
      before { run.update!(error: true) }
      
      it 'updates the run as failed' do
        expect {
          run.complete!(end_time)
          run.reload
        }.to change(run, :status).from('pending').to('failed')
      end
    end
  end

  describe 'duration calculation' do
    let(:start_time) { Time.current }
    let(:end_time) { start_time + 2.hours }
    let(:run) { create(:run, started_at: start_time) }

    before do
      run.update!(ended_at: end_time)
      run.calculate_duration
    end

    it 'calculates the duration correctly' do
      expect(run.duration).to eq(7200) # 2 hours in seconds
    end
  end

  describe 'status transitions' do
    let(:run) { create(:run, status: :pending) }

    it 'allows transition from pending to successful' do
      expect { run.update!(status: :successful) }
        .to change(run, :status).from('pending').to('successful')
    end

    it 'allows transition from pending to failed' do
      expect { run.update!(status: :failed) }
        .to change(run, :status).from('pending').to('failed')
    end

    it 'does not allow transition from successful to pending' do
      run.update!(status: :successful)
      expect { run.update!(status: :pending) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'validations' do
    let(:run) { build(:run) }

    it 'is valid with valid attributes' do
      expect(run).to be_valid
    end

    it 'is not valid without a flow' do
      run.flow = nil
      expect(run).not_to be_valid
    end

    it 'is not valid without a started_at' do
      run.started_at = nil
      expect(run).not_to be_valid
    end
  end
end
