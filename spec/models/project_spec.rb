require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:flows).dependent(:nullify) }
  end

  describe 'callbacks' do
    let(:project) { build(:project) }

    it 'generates a public token before create' do
      expect(project.public_token).to be_nil
      project.save!
      expect(project.public_token).to be_present
      expect(project.public_token.length).to eq(40) # 20 bytes in hex
    end

    it 'generates a secret token before create' do
      expect(project.secret_token).to be_nil
      project.save!
      expect(project.secret_token).to be_present
      expect(project.secret_token.length).to eq(64) # 32 bytes in hex
    end
  end

  describe '#regenerate_public_token!' do
    let(:project) { create(:project) }
    let!(:original_token) { project.public_token }

    it 'generates a new public token' do
      expect {
        project.regenerate_public_token!
      }.to change(project, :public_token)
      
      expect(project.public_token).not_to eq(original_token)
      expect(project.public_token.length).to eq(40)
    end
  end

  describe '#regenerate_secret_token!' do
    let(:project) { create(:project) }
    let(:original_token) { project.secret_token.dup }

    it 'generates a new secret token' do
      expect {
        project.regenerate_secret_token!
      }.to change { project.reload.secret_token }.from(original_token)
      
      expect(project.secret_token).not_to eq(original_token)
      expect(project.secret_token.length).to eq(64)
    end
  end

  describe 'token generation' do
    it 'generates unique tokens' do
      project1 = create(:project)
      project2 = create(:project)
      
      expect(project1.public_token).not_to eq(project2.public_token)
      expect(project1.secret_token).not_to eq(project2.secret_token)
    end
  end
end
