require 'rails_helper'

RSpec.describe BirthdayNotificationService, type: :service do
  let!(:user) { create(:user, birthday_date: Date.today, location: 'Asia/Ho_Chi_Minh') }
  let!(:other_user) { create(:user, birthday_date: Date.tomorrow) }
  let(:today_local) { Time.current.in_time_zone(user.location).to_date }
  let(:user_birthday) { user.birthday_date.change(year: today_local.year) }
  let(:scheduled_time) { Time.use_zone(user.location) { Time.zone.local(today_local.year, user_birthday.month, user_birthday.day, 9, 0, 0) } }

  describe '.schedule_today_notifications' do
    before { allow(Sidekiq.logger).to receive(:info) }

    context 'when user has a birthday today' do
      it 'creates a scheduled notification if not exists' do
        expect {
          described_class.schedule_today_notifications
        }.to change(BirthdayNotification, :count).by(1)

        notification = BirthdayNotification.last
        expect(notification.user).to eq(user)
        expect(notification.birthday).to eq(user_birthday)
        expect(notification).to be_scheduled
        expect(notification.retry_count).to eq(0)
      end

      it 'schedules the notification job' do
        allow(BirthdayNotificationJob).to receive(:perform_at)

        described_class.schedule_today_notifications

        notification = BirthdayNotification.last
        expect(BirthdayNotificationJob).to have_received(:perform_at).with(scheduled_time, notification.id)
      end
    end

    context 'when notification already exists' do
      let!(:notification) { create(:birthday_notification, user: user, birthday: user_birthday, status: :scheduled) }

      it 'does not create a duplicate notification' do
        expect {
          described_class.schedule_today_notifications
        }.not_to change(BirthdayNotification, :count)
      end

      it 're-schedules the existing notification' do
        allow(BirthdayNotificationJob).to receive(:perform_at)

        described_class.schedule_today_notifications

        expect(BirthdayNotificationJob).to have_received(:perform_at).with(scheduled_time, notification.id)
      end
    end

    context 'when notification errored and has retries left' do
      let!(:notification) { create(:birthday_notification, user: user, birthday: user_birthday, status: :errored, retry_count: 2) }

      it 'retries scheduling the notification' do
        allow(BirthdayNotificationJob).to receive(:perform_at)

        described_class.schedule_today_notifications

        expect(BirthdayNotificationJob).to have_received(:perform_at).with(scheduled_time, notification.id)
      end
    end

    context 'when notification errored but max retries exceeded' do
      let!(:notification) { create(:birthday_notification, user: user, birthday: user_birthday, status: :errored, retry_count: BirthdayNotification::MAX_RETRIES) }

      it 'does not reschedule the notification' do
        allow(BirthdayNotificationJob).to receive(:perform_at)

        described_class.schedule_today_notifications

        expect(BirthdayNotificationJob).not_to have_received(:perform_at)
      end
    end

    context 'when user does not have a birthday today' do
      it 'does not create a notification' do
        expect {
          described_class.schedule_today_notifications
      }.to change(BirthdayNotification, :count).by(1)

        notification = BirthdayNotification.last
        expect(notification.user).to eq(user)
        expect(notification.birthday).to eq(user.birthday_date)
        expect(notification).not_to be_falsey
      end
    end
  end

  describe '.send_scheduled_notifications' do
    let!(:scheduled_notifications) { create_list(:birthday_notification, 3, status: :scheduled) }

    it 'enqueues all scheduled notifications' do
      allow(BirthdayNotificationJob).to receive(:perform_async)

      described_class.send_scheduled_notifications

      scheduled_notifications.each do |notification|
        expect(BirthdayNotificationJob).to have_received(:perform_async).with(notification.id)
      end
    end
  end

  describe '.retry_failed_notifications' do
    let!(:failed_notifications) { create_list(:birthday_notification, 2, status: :errored, retry_count: 2) }
    let!(:max_retries_exceeded) { create(:birthday_notification, status: :errored, retry_count: BirthdayNotification::MAX_RETRIES) }

    it 'retries notifications that have not exceeded max retries' do
      allow(BirthdayNotificationJob).to receive(:perform_async)

      described_class.retry_failed_notifications

      failed_notifications.each do |notification|
        expect(BirthdayNotificationJob).to have_received(:perform_async).with(notification.id)
      end
    end

    it 'does not retry notifications that have exceeded max retries' do
      allow(BirthdayNotificationJob).to receive(:perform_async)

      described_class.retry_failed_notifications

      expect(BirthdayNotificationJob).not_to have_received(:perform_async).with(max_retries_exceeded.id)
    end
  end
end
