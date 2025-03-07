require 'rails_helper'

RSpec.describe BirthdayNotificationJobs::RetryFailedBirthdayNotificationsJob, type: :job do
  describe "#perform" do
    it "calls BirthdayNotificationService.retry_failed_notifications" do
      expect(BirthdayNotificationService).to receive(:retry_failed_notifications)
      described_class.new.perform
    end
  end
end
