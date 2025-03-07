require 'rails_helper'

RSpec.describe BirthdayNotifications::SendBirthdayNotificationsJob, type: :job do
  describe "#perform" do
    it "calls BirthdayNotifications::BirthdayNotificationService.new().send_scheduled_notifications" do
      expect(BirthdayNotifications::BirthdayNotificationService.new).to receive(:send_scheduled_notifications)
      described_class.new().perform
    end
  end
end
