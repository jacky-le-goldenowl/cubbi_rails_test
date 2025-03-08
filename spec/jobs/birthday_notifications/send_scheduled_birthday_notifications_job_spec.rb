require 'rails_helper'

RSpec.describe BirthdayNotifications::SendScheduledBirthdayNotificationsJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    it "calls the SendScheduledNotificationService" do
      expect(BirthdayNotifications::SendScheduledNotificationService).to receive(:call)

      perform_enqueued_jobs do
        described_class.perform_now
      end
    end
  end
end
