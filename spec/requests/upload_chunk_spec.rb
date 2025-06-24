require 'rails_helper'

RSpec.describe "Upload Chunk", type: :request do
  fixtures :upload_sessions
  describe "#create" do
    context 'with invalid upload session' do
      it "returns not found with invalid upload session" do
        post "/api/v1/upload_sessions/1234/upload_chunks", :params => { sequence_no: 1 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with valid upload session" do
      context "with valid data" do
        it "creates a chunk" do
          upload_session = upload_sessions(:incomplete_upload_session)
          headers = { "CONTENT_TYPE" => "application/json" }
          expect {
            post "/api/v1/upload_sessions/#{upload_session.id}/upload_chunks", :params => { sequence_no: 1, document: file_fixture_upload('chunk_0.png', 'image/png') }
          }.to change { UploadChunk.count }.by(1)
          expect(response).to have_http_status(:created) 
        end
      end

      context "with invalid data" do
        it "returns errors" do
          upload_session = upload_sessions(:test_upload_session)
          headers = { "CONTENT_TYPE" => "application/json" }
          expect {
            post "/api/v1/upload_sessions/#{upload_session.id}/upload_chunks", :params => { sequence_no: 1 }
          }.to change { UploadChunk.count }.by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          errors = JSON.parse(response.body)["errors"]
          expect(errors).to be_present
        end
      end
    end

  end
end