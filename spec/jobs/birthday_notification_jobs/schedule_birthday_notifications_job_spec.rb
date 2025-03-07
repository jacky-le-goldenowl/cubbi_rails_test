require 'rails_helper'

RSpec.describe BirthdayNotificationJobs::ScheduleBirthdayNotificationsJob, type: :job do
  describe "#perform" do
    it "calls BirthdayNotificationService.schedule_today_notifications" do
      expect(BirthdayNotificationService).to receive(:schedule_today_notifications)
      described_class.new.perform
    end
  end
end
