require 'rails_helper'
require 'webmock/rspec'

RSpec.describe HookbinRequestService, type: :service do
  let(:hookbin_url) { "https://hookb.in/test-endpoint_example" }
  let(:payload) { { message: "Hello, Jacky Hookbin!" } }

  before do
    allow(ENV).to receive(:[]).with("HOOKBIN_URL").and_return(hookbin_url)
  end

  describe '#send_post_request' do
    context 'when the request is successful' do
      before do
        stub_request(:post, hookbin_url)
          .with(
            body: payload.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(status: 200, body: { success: true }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'sends a POST request with the correct payload' do
        response = described_class.call(payload)

        expect(response.code).to eq("200")
        expect(response.body).to eq({ success: true }.to_json)

        expect(WebMock).to have_requested(:post, hookbin_url)
          .with(body: payload.to_json, headers: { 'Content-Type' => 'application/json' }).once
      end
    end

    context 'when the request fails with a server error' do
      before do
        stub_request(:post, hookbin_url)
          .to_return(status: 500, body: { error: "Internal Server Error" }.to_json)
      end

      it 'returns a 500 response' do
        response = described_class.call(payload)

        expect(response.code).to eq("500")
        expect(response.body).to eq({ error: "Internal Server Error" }.to_json)
      end
    end

    context 'when the request times out' do
      before do
        stub_request(:post, hookbin_url).to_timeout
      end

      it 'raises a timeout error' do
        expect {
          described_class.call(payload)
        }.to raise_error(Net::OpenTimeout)
      end
    end
  end
end
