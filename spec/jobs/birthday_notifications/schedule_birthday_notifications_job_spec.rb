require 'rails_helper'

RSpec.describe BirthdayNotifications::ScheduleBirthdayNotificationsJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    it "calls the ScheduleTodayNotificationService" do
      expect(BirthdayNotifications::ScheduleTodayNotificationService)
        .to receive(:call)

      perform_enqueued_jobs do
        described_class.perform_now
      end
    end
  end
end
