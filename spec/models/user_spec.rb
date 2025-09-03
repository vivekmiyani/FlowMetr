require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    let(:user_attributes) do
      {
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end
    it { should validate_presence_of(:email) }
    it 'validates uniqueness of email case-insensitively' do
      create(:user, user_attributes)
      new_user = build(:user, email: 'TEST@example.com')
      expect(new_user).to be_invalid
      expect(new_user.errors[:email]).to include('has already been taken')
    end
    it { should validate_presence_of(:password) }
  end

  describe 'associations' do
    it { should have_many(:projects).dependent(:destroy) }
    it { should have_many(:flows).dependent(:destroy) }
    it { should have_many(:runs).through(:flows) }
    it { should have_many(:measurement_logs).through(:runs) }
    it { should belong_to(:plan).optional }
  end

  describe 'callbacks' do
    it 'creates a default project after create' do
      user = build(:user)
      expect { user.save! }.to change(Project, :count).by(1)
      expect(user.projects.first.name).to eq('Default')
    end
  end

  describe '#premium?' do
    let(:user) { create(:user) }
    let(:premium_plan) { create(:plan, name: 'Premium', price_id: 'price_123') }
    let(:free_plan) { create(:plan, name: 'Free', price_id: 'free') }

    context 'when user has a paid plan' do
      before { user.update(plan: premium_plan) }
      
      it 'returns true' do
        expect(user).to be_premium
      end
    end

    context 'when user has a free plan' do
      before { user.update(plan: free_plan) }
      
      it 'returns false' do
        expect(user).not_to be_premium
      end
    end
  end

  describe '#monthly_measurement_count' do
    let(:user) { create(:user) }
    let(:flow) { create(:flow, user: user) }
    let!(:run) { create(:run, flow: flow) }

    before do
      create_list(:measurement_log, 3, 
        run: run, 
        measurement_point: create(:measurement_point, flow: flow),
        created_at: Time.current.beginning_of_month
      )
      create_list(:measurement_log, 2,
        run: run,
        measurement_point: create(:measurement_point, flow: flow),
        created_at: 2.months.ago
      )
    end

    it 'returns count of measurements for current month' do
      expect(user.monthly_measurement_count).to eq(3)
    end
  end

  describe '#flow_limit_reached?' do
    let(:user) { create(:user) }
    let!(:flows) { create_list(:flow, 5, user: user) }

    context 'when user is on free plan' do
      before { allow(user).to receive(:premium?).and_return(false) }
      
      it 'returns true when flow limit is reached' do
        expect(user.flow_limit_reached?).to be_truthy
      end
    end

    context 'when user is premium' do
      before { allow(user).to receive(:premium?).and_return(true) }
      
      it 'returns false' do
        expect(user.flow_limit_reached?).to be_falsey
      end
    end
  end

  describe '#on_trial?' do
    let(:user) { create(:user, trial_ends_at: 1.week.from_now) }
    
    it 'returns true when within trial period' do
      expect(user).to be_on_trial
    end

    it 'returns false when trial has ended' do
      user.trial_ends_at = 1.week.ago
      expect(user).not_to be_on_trial
    end
  end
end
