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
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to allow_value("user@example.com").for(:email) }
    it { is_expected.not_to allow_value("invalid_email").for(:email) }
    it { is_expected.to validate_presence_of(:birthday_date) }
  end

  describe "callbacks" do
    let(:user) { create(:user, birthday_date: Date.new(1997, 1, 1), email: "test@example.com") }

    context "when birthday_date is updated" do
      it "calls BirthdayNotifications::UpdateBirthdayNotificationService" do
        expect(BirthdayNotifications::UpdateBirthdayNotificationService)
          .to receive(:call).with(user)

        user.update!(birthday_date: Date.new(1998, 1, 1))
      end
    end

    context "when birthday_date is not updated" do
      it "does not call BirthdayNotifications::UpdateBirthdayNotificationService" do
        expect(BirthdayNotifications::UpdateBirthdayNotificationService)
          .not_to receive(:call)

        user.update!(email: "new_email@example.com")
      end
    end
  end
end
