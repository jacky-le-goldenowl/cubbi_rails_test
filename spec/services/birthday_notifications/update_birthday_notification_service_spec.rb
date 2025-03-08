require 'rails_helper'

RSpec.describe BirthdayNotifications::UpdateBirthdayNotificationService, type: :service do
  let(:user_timezone) { "America/New_York" }
  let(:today_local)   { Time.current.in_time_zone(user_timezone).to_date }
  let(:original_birthday) { today_local.prev_year }
  let(:user) { create(:user, birthday_date: original_birthday, location: user_timezone) }
  let!(:notification) do
    create(
      :birthday_notification,
      user: user,
      birthday: original_birthday.change(year: today_local.year),
      status: :scheduled,
      retry_count: 0
    )
  end

  subject { described_class.new(user).call }

  context "when the user's birthday_date has changed" do
    before do
      user.update!(birthday_date: today_local.next_day)
    end

    it "updates the existing scheduled notification to cancelled" do
      expect {
        subject
        notification.reload
      }.to change { notification.status }.from("scheduled").to("cancelled")
    end
  end

  context "when the user's birthday_date remains the same" do
    it "does not change the notification status" do
      expect {
        subject
        notification.reload
      }.not_to change { notification.status }
    end
  end

  context "when there is no scheduled notification" do
    before do
      user.birthday_notifications.destroy_all
    end

    it "does nothing and does not raise an error" do
      expect { subject }.not_to raise_error
    end
  end
end
