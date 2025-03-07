require 'rails_helper'

RSpec.describe BirthdayNotificationJob, type: :job do
  let(:user) { create(:user, first_name: "Jacky", last_name: "Le") }
  let(:notification) { create(:birthday_notification, user: user, status: :scheduled, retry_count: initial_retry_count) }
  let(:initial_retry_count) { 0 }
  let(:job) { described_class.new }
  let(:message) { "Hey, #{user.first_name} #{user.last_name} it’s your birthday" }

  describe "#perform" do
    context "when the HTTP response is successful" do
      before do
        success_response = instance_double(Net::HTTPSuccess)
        allow(success_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        hookbin_service_instance = instance_double(HookbinRequestService)
        allow(HookbinRequestService).to receive(:new).and_return(hookbin_service_instance)
        allow(hookbin_service_instance).to receive(:send_post_request).with(message: message).and_return(success_response)
      end

      it "updates the notification status to sent" do
        job.perform(notification.id)
        expect(notification.reload.status).to eq("sent")
      end
    end

    context "when the HTTP response is not successful and retry_count is less than MAX_RETRIES" do
      before do
        error_response = instance_double(Net::HTTPBadRequest)
        allow(error_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(HookbinRequestService).to receive(:send_post_request).with(message: message).and_return(error_response)
      end

      it "increments the retry_count and sets status to failed" do
        expect {
          job.perform(notification.id)
        }.to change { notification.reload.retry_count }.by(1)
        expect(notification.reload.status).to eq("failed")
      end
    end

    context "when the HTTP response is not successful and retry_count reaches MAX_RETRIES" do
      let(:initial_retry_count) { BirthdayNotification::MAX_RETRIES - 1 }

      before do
        error_response = instance_double(Net::HTTPBadRequest)
        allow(error_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(HookbinRequestService).to receive(:send_post_request).with(message: message).and_return(error_response)
        allow(Rails.logger).to receive(:error)
      end

      it "increments the retry_count and does not update status (logs error)" do
        expect {
          job.perform(notification.id)
        }.to change { notification.reload.retry_count }.by(1)
        expect(notification.reload.retry_count).to eq(BirthdayNotification::MAX_RETRIES)
        expect(Rails.logger).to have_received(:error).with(
          "RETRY LIMIT EXCEEDED: Notification #{notification.id} failed after #{BirthdayNotification::MAX_RETRIES} retries"
        )
      end
    end

    context "when an exception is raised during processing" do
      before do
        allow(HookbinRequestService).to receive(:send_post_request).with(message: message).and_raise(StandardError.new("Some error"))
        allow(Rails.logger).to receive(:error)
      end

      it "rescues the error, increments retry_count and updates status to failed" do
        expect {
          job.perform(notification.id)
        }.to change { notification.reload.retry_count }.by(1)
        expect(notification.reload.status).to eq("failed")
        expect(Rails.logger).to have_received(:error).with(/Error sending notification #{notification.id}: Some error/)
      end
    end
  end
end
