require 'rails_helper'

RSpec.describe BirthdayNotification, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "enums" do
    it do
      is_expected.to define_enum_for(:status).
        with_values(scheduled: 0, sent: 1, failed: 2, cancelled: 3)
    end
  end

  describe "validations" do
    subject { create(:birthday_notification) }

    it do
      is_expected.to validate_uniqueness_of(:birthday).
        scoped_to(:user_id).
        with_message("Notification for this birthday already exists.")
    end

    it do
      is_expected.to validate_numericality_of(:retry_count).
        only_integer.
        is_greater_than_or_equal_to(0).
        is_less_than_or_equal_to(BirthdayNotification::MAX_RETRIES + 1)
    end
  end

  describe "constants" do
    it "defines MAX_RETRIES correctly" do
      expect(BirthdayNotification::MAX_RETRIES).to eq(2)
    end

    it "defines NOTIFICATION_TIME correctly" do
      expect(BirthdayNotification::NOTIFICATION_TIME).to eq({ hour: 9, minute: 0 })
    end
  end
end
