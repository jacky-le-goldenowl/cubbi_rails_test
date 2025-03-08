require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  describe "POST /api/v1/users" do
    let(:valid_attributes) do
      {
        email: "Jacky.le@example.com",
        first_name: "Jacky",
        last_name: "le",
        birthday_date: "1990-01-01",
        location: "UTC"
      }
    end

    let(:invalid_attributes) do
      {
        email: "",
        first_name: "Jacky",
        last_name: "le",
        birthday_date: "1990-01-01",
        location: "UTC"
      }
    end

    context "when request is valid" do
      before do
        post "/api/v1/users", params: { user: valid_attributes }
      end

      it "creates a new user" do
        expect(User.last.email).to eq(valid_attributes[:email])
      end

      it "returns status code 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the created user in the response" do
        json_response = JSON.parse(response.body)
        expect(json_response["email"]).to eq(valid_attributes[:email])
        expect(json_response["first_name"]).to eq(valid_attributes[:first_name])
      end
    end

    context "when request is invalid" do
      before do
        post "/api/v1/users", params: { user: invalid_attributes }
      end

      it "does not create a new user" do
        expect(User.where(email: invalid_attributes[:email])).to be_empty
      end

      it "returns status code 422" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns the validation errors" do
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key("email")
      end
    end
  end

  describe "DELETE /api/v1/users/:id" do
    let!(:user) { create(:user) }

    it "destroys the user" do
      expect {
        delete "/api/v1/users/#{user.id}"
      }.to change(User, :count).by(-1)
    end

    it "returns a successful response" do
      delete "/api/v1/users/#{user.id}"
      expect(response).to have_http_status(:no_content).or have_http_status(:ok)
    end
  end
end
