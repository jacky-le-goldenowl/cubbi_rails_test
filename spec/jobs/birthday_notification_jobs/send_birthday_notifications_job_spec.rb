require 'rails_helper'

RSpec.describe BirthdayNotificationJobs::SendBirthdayNotificationsJob, type: :job do
  describe "#perform" do
    it "calls BirthdayNotificationService.send_scheduled_notifications" do
      expect(BirthdayNotificationService).to receive(:send_scheduled_notifications)
      described_class.new.perform
    end
  end
end
