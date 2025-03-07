# spec/jobs/birthday_notification_job_spec.rb
require 'rails_helper'

RSpec.describe BirthdayNotificationJob, type: :job do
  include ActiveJob::TestHelper

  let(:notification) { create(:birthday_notification) }
  let(:user)         { notification.user }

  describe "#perform" do
    context "when the notification exists and HookbinRequestService returns success" do
      let(:success_response) { instance_double(Net::HTTPOK) }

      before do
        allow(success_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(HookbinRequestService).to receive(:call).and_return(success_response)
      end

      it "calls the service, does not raise an exception, and updates the status to sent (via after_perform)" do
        expected_message = "Hey, #{user.first_name} #{user.last_name}, it's your birthday!"
        expect(HookbinRequestService).to receive(:call).with({ message: expected_message })

        described_class.perform_now(notification.id)

        expect(notification.reload.status).to eq("sent")
      end
    end

    context "when the notification exists but HookbinRequestService returns an error" do
      let(:failure_response) { instance_double(Net::HTTPBadRequest) }

      before do
        allow(failure_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(HookbinRequestService).to receive(:call).and_return(failure_response)
      end

      it "raises an exception, triggers rescue_from to increment retry_count, and updates the status to failed" do
        expect {
          described_class.perform_now(notification.id)
        }.to raise_error(StandardError, "Failed to send notification #{notification.id}")

        notification.reload
        expect(notification.status).to eq("failed")
      end
    end

    context "when the notification is not found" do
      it "does not call HookbinRequestService and logs an error" do
        invalid_id = -1
        expect(HookbinRequestService).not_to receive(:call)
        expect(Rails.logger).to receive(:error).with(/Notification with id #{invalid_id} not found/)

        described_class.perform_now(invalid_id)
      end
    end
  end
end
