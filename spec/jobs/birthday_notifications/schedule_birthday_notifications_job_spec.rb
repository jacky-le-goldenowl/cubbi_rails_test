require 'rails_helper'

RSpec.describe BirthdayNotifications::ScheduleBirthdayNotificationsJob, type: :job do
  describe "#perform" do
    it "calls BirthdayNotifications::BirthdayNotificationService.new().schedule_today_notifications" do
      expect(BirthdayNotifications::BirthdayNotificationService.new).to receive(:schedule_today_notifications)
      described_class.new().perform
    end
  end
end
