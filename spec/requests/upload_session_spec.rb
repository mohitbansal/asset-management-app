require 'rails_helper'

RSpec.describe "Upload session", type: :request do
  fixtures :upload_sessions, :upload_chunks, "active_storage/attachments", "active_storage/blobs"

  describe "#create" do
    context "with valid data" do
      it "creates a upload session" do
        headers = { "CONTENT_TYPE" => "application/json" }
        expect {
          post "/api/v1/upload_sessions", :params => { :chunk_size => 1024, total_chunks: 5, content_type: 'image/png' }
        }.to change { UploadSession.count }.by(1)
        expect(response).to have_http_status(:created) 
        res = JSON.parse(response.body)
        expect(res).to eq({"id" => UploadSession.last.id})
      end
    end

    context "with invalid data" do
      it "returns errors" do
        headers = { "CONTENT_TYPE" => "application/json" }
        expect {
          post "/api/v1/upload_sessions", :params => { chunk_size: 5620 }
        }.to change { UploadSession.count }.by(0)
        expect(response).to have_http_status(:unprocessable_entity) 
        res = JSON.parse(response.body)
        expect(res["errors"]).to be_present
      end
    end
  end

  describe "#status" do
    it "returns status" do
      upload_session = upload_sessions(:test_upload_session)
      get "/api/v1/upload_sessions/#{upload_session.id}/status"
      expect(response).to have_http_status(:success)
      res = JSON.parse(response.body)
      expect(res).to eq({
        "chunk_size" => 1024, 
        "total_chunks" => 9, 
        "status" => "complete"
        })
    end

  end

  describe "#complete" do

    context "when chunks are not completely uploaded" do
      let(:upload_session) { upload_sessions(:incomplete_upload_session) }
      it "returns errors" do
        headers = { "CONTENT_TYPE" => "application/json" }
        post "/api/v1/upload_sessions/#{upload_session.id}/complete"
        expect(response).to have_http_status(:unprocessable_entity)
        res = JSON.parse(response.body)
        expect(res["errors"]).to be_present
      end
    end

    context "when all chunks have been uploaded" do
      it "marks the session as complete" do
        upload_session = upload_sessions(:test_upload_session)
        upload_session.update_column(:status, "incomplete")
        expect(FileProcessingJob).to receive(:perform_later).with(upload_session.id)
        
        headers = { "CONTENT_TYPE" => "application/json" }
        post "/api/v1/upload_sessions/#{upload_session.id}/complete"
        
        expect(response).to have_http_status(:success)

        upload_session.reload
        
        expect(upload_session.complete?).to be true

      end   
    end
  end
end

