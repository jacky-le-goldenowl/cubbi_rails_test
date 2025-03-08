require 'rails_helper'

RSpec.describe BirthdayNotifications::SendBirthdayNotificationJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user, first_name: "John", last_name: "Doe") }
  let!(:notification) { create(:birthday_notification, user: user, status: :scheduled, retry_count: 0) }
  let(:notification_id) { notification.id }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  after do
    clear_enqueued_jobs
  end

  subject { described_class.new.call }

  describe "#perform" do
    context "when notification does not exist" do
      it "logs an error and exits without calling HookbinRequestService" do
        fake_logger = instance_double(Logger)
        allow(Rails).to receive(:logger).and_return(fake_logger)
        expect(fake_logger).to receive(:error).with("Notification with id 999 not found. Exiting job.")
        expect(HookbinRequestService).not_to receive(:call)

        perform_enqueued_jobs do
          described_class.perform_now(999)
        end
      end
    end

    context "when notification is already sent" do
      before do
        notification.update!(status: :sent)
      end

      it "logs an error and does not call HookbinRequestService" do
        fake_logger = instance_double(Logger)
        allow(Rails).to receive(:logger).and_return(fake_logger)
        expect(fake_logger).to receive(:error).with("Notification with id #{notification.id} not found. Exiting job.")
        expect(HookbinRequestService).not_to receive(:call)

        perform_enqueued_jobs do
          described_class.perform_now(notification_id)
        end
      end
    end

    context "when job performs successfully" do
      let(:fake_success_response) do
        double("Net::HTTPSuccess", is_a?: true)
      end

      before do
        allow(HookbinRequestService).to receive(:call).and_return(fake_success_response)
      end

      it "updates notification status to sent via after_perform callback" do
        perform_enqueued_jobs do
          described_class.perform_now(notification_id)
        end

        notification.reload
        expect(notification.status).to eq("sent")
      end
    end

    context "when job fails to send notification" do
      let(:fake_failure_response) { instance_double(Net::HTTPResponse) }

      before do
        allow(HookbinRequestService).to receive(:call).and_return(fake_failure_response)
      end

      it "updates notification status to failed and increments retry_count" do
        expect {
          perform_enqueued_jobs do
            expect {
              described_class.perform_now(notification_id)
            }.to raise_error(StandardError, /Failed to send notification #{notification_id}/)
          end
        }.to change { notification.reload.retry_count }.by(1)

        notification.reload
        expect(notification.status).to eq("failed")
      end
    end
  end
end
