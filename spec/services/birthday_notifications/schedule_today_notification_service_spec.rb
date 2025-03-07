require 'rails_helper'

RSpec.describe BirthdayNotifications::ScheduleTodayNotificationService, type: :service do
  include ActiveJob::TestHelper

  describe "#call" do
    let(:today) { Time.current.in_time_zone("UTC").to_date }
    let(:tomorrow) { today + 1.day }

    before do
      ActiveJob::Base.queue_adapter = :test
    end

    after do
      clear_enqueued_jobs
    end

    subject { described_class.new.call }

    context "when user's birthday is today" do
      let(:user_birthday_today) { create(:user, birthday_date: today, location: "UTC") }

      it "creates a notification and enqueues a job" do
        expect(BirthdayNotification.find_by(user: user_birthday_today, birthday: today)).to be_nil

        subject

        notification = BirthdayNotification.find_by(user: user_birthday_today, birthday: today)
        expect(notification).to be_present

        expected_time = described_class.new.send(:scheduled_time, user_birthday_today)
        expect(BirthdayNotifications::SendBirthdayNotificationJob).to have_been_enqueued
          .with(notification.id)
          .at(expected_time)
      end
    end

    context "when user's birthday is not today" do
      let(:user_not_birthday) { create(:user, birthday_date: tomorrow, location: "UTC") }

      it "does not create a notification or enqueue a job" do
        expect { subject }
          .not_to have_enqueued_job(BirthdayNotifications::SendBirthdayNotificationJob)
        notification = BirthdayNotification.find_by(user: user_not_birthday, birthday: today)
        expect(notification).to be_nil
      end
    end

    context "when notification is not eligible for scheduling" do
      let(:user) { create(:user, birthday_date: today, location: "UTC") }
      let(:notification) do
        create(
          :birthday_notification,
          user: user,
          birthday: today,
          status: BirthdayNotification.statuses[:sent]
        )
      end

      it "does not enqueue the job" do
        expect { subject }
          .not_to have_enqueued_job(BirthdayNotifications::SendBirthdayNotificationJob)
      end
    end
  end
end
