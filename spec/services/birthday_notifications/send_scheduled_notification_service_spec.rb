require 'rails_helper'

RSpec.describe BirthdayNotifications::SendScheduledNotificationService, type: :service do
  include ActiveJob::TestHelper

  describe "#call" do
    before do
      ActiveJob::Base.queue_adapter = :test
    end

    after do
      clear_enqueued_jobs
    end

    subject { described_class.new.call }

    context "when there are scheduled notifications" do
      let!(:notification1) { create(:birthday_notification, status: :scheduled) }
      let!(:notification2) { create(:birthday_notification, status: :scheduled) }
      let!(:notification3) { create(:birthday_notification, status: :failed) }

      it "enqueues a job for each scheduled notification" do
        subject

        enqueued_ids = ActiveJob::Base.queue_adapter.enqueued_jobs.map { |job| job[:args].first }
        expected_ids = [ notification1.id, notification2.id ]

        expect(enqueued_ids).to match_array(expected_ids)
      end
    end

    context "when there are no scheduled notifications" do
      let!(:notification) { create(:birthday_notification, status: :failed) }

      it "does not enqueue any job" do
        subject
        expect(ActiveJob::Base.queue_adapter.enqueued_jobs).to be_empty
      end
    end
  end
end
