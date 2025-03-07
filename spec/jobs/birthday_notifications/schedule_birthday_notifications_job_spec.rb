require "rails_helper"

RSpec.describe BirthdayNotifications::ScheduleBirthdayNotificationsJob, type: :job do
  describe "#perform" do
    it "instantiates the BirthdayNotificationService and calls schedule_today_notifications" do
      service_instance = instance_double(BirthdayNotifications::BirthdayNotificationService)

      expect(BirthdayNotifications::BirthdayNotificationService)
        .to receive(:new)
        .and_return(service_instance)
      expect(service_instance)
        .to receive(:schedule_today_notifications)

      described_class.perform_now
    end
  end
end
