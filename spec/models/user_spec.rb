require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it 'has many birthday_notifications' do
      expect(
        described_class.reflect_on_association(:birthday_notifications
      ).macro).to eq(:has_many)
    end
  end

  describe 'validations' do
    let!(:existing_user) { create(:user, email: 'test@example.com') }

    it 'validates uniqueness of email' do
      new_user = build(:user, email: 'test@example.com')
      expect(new_user).not_to be_valid
      expect(new_user.errors[:email]).to include('has already been taken')
    end

    it 'allows valid email format' do
      user = build(:user, email: 'valid@example.com')
      expect(user).to be_valid
    end

    it 'rejects invalid email format' do
      user = build(:user, email: 'invalid_email')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end
  end
end
