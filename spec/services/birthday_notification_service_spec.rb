# spec/services/birthday_notifications/birthday_notification_service_spec.rb
require 'rails_helper'

RSpec.describe BirthdayNotifications::BirthdayNotificationService, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  let(:service) { described_class.new }

  describe "#schedule_today_notifications" do
    context "when user's birthday is today" do
      before { travel_to Time.zone.local(2024, 5, 15, 8, 0, 0) }
      after  { travel_back }

      let(:current_date) { Date.current }
      let!(:user) { create(:user, birthday_date: current_date, location: "UTC") }

      it "creates a new scheduled birthday notification and enqueues a job with the correct wait time" do
        expected_scheduled_time = Time.use_zone("UTC") do
          Time.zone.local(current_date.year, current_date.month, current_date.day, 9, 0, 0)
        end

        # Expect the job to be enqueued with the proper scheduled time.
        job_double = instance_double("ActiveJob::EnqueuedJob")
        expect(BirthdayNotificationJob).to receive(:set)
          .with(wait_until: expected_scheduled_time)
          .and_return(job_double)
        expect(job_double).to receive(:perform_later).with(instance_of(Integer))

        expect {
          service.schedule_today_notifications
        }.to change { BirthdayNotification.count }.by(1)

        notification = BirthdayNotification.last
        expect(notification.status).to eq("scheduled")
        expect(notification.retry_count).to eq(0)
      end
    end

    context "when user's birthday is not today" do
      before { travel_to Time.zone.local(2024, 5, 15, 8, 0, 0) }
      after  { travel_back }

      let!(:user) { create(:user, birthday_date: Date.tomorrow, location: "UTC") }

      it "does not create any birthday notifications" do
        expect(BirthdayNotificationJob).not_to receive(:set)
        expect {
          service.schedule_today_notifications
        }.not_to change { BirthdayNotification.count }
      end
    end

    context "when a notification already exists and is scheduled" do
      before { travel_to Time.zone.local(2024, 5, 15, 8, 0, 0) }
      after  { travel_back }

      let(:current_date) { Date.current }
      let!(:user) { create(:user, birthday_date: current_date, location: "UTC") }
      let!(:notification) do
        create(:birthday_notification, user: user, birthday: current_date,
               status: :scheduled, retry_count: 0)
      end

      it "does not create a duplicate notification but enqueues a job" do
        expected_scheduled_time = Time.use_zone("UTC") do
          Time.zone.local(current_date.year, current_date.month, current_date.day, 9, 0, 0)
        end

        job_double = instance_double("ActiveJob::EnqueuedJob")
        expect(BirthdayNotificationJob).to receive(:set)
          .with(wait_until: expected_scheduled_time)
          .and_return(job_double)
        expect(job_double).to receive(:perform_later).with(notification.id)

        expect {
          service.schedule_today_notifications
        }.not_to change { BirthdayNotification.count }
      end
    end

    context "when a notification already exists but has failed and is eligible for retry" do
      before { travel_to Time.zone.local(2024, 5, 15, 8, 0, 0) }
      after  { travel_back }

      let(:current_date) { Date.current }
      let!(:user) { create(:user, birthday_date: current_date, location: "UTC") }
      let!(:notification) do
        create(:birthday_notification, user: user, birthday: current_date,
               status: :failed, retry_count: BirthdayNotification::MAX_RETRIES - 1)
      end

      it "enqueues a job for the failed notification" do
        expected_scheduled_time = Time.use_zone("UTC") do
          Time.zone.local(current_date.year, current_date.month, current_date.day, 9, 0, 0)
        end

        job_double = instance_double("ActiveJob::EnqueuedJob")
        expect(BirthdayNotificationJob).to receive(:set)
          .with(wait_until: expected_scheduled_time)
          .and_return(job_double)
        expect(job_double).to receive(:perform_later).with(notification.id)

        expect {
          service.schedule_today_notifications
        }.not_to change { BirthdayNotification.count }
      end
    end
  end

  describe "#send_scheduled_notifications" do
    let!(:notifications) { create_list(:birthday_notification, 3, status: :scheduled) }

    it "enqueues a job for each scheduled notification" do
      notifications.each do |notification|
        expect(BirthdayNotificationJob).to receive(:perform_later).with(notification.id)
      end

      service.send_scheduled_notifications
    end
  end
end
