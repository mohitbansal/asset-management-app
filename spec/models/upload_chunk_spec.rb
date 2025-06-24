require 'rails_helper'

RSpec.describe UploadChunk, type: :model do
  fixtures :upload_sessions, :upload_chunks, "active_storage/attachments", "active_storage/blobs"
  it { should have_one_attached(:document) }
  it { should belong_to(:upload_session) }
  it { should validate_presence_of(:document) }
  it { should validate_presence_of(:sequence_no) }
  it { should validate_uniqueness_of(:sequence_no).scoped_to(:upload_session_id) }

  describe '#ensure_chunk_size_within_limit' do
    it "returns error when large chunk" do
      chunk = upload_chunks(:large_chunk)
      chunk.valid?
      expect(chunk.errors[:document]).to include("size exceeds maximum chunk size")
    end
  end

  describe '#ensure_total_chunks_within_limit' do
    it "returns error when limit exceeds" do
      upload_session = upload_sessions(:test_upload_session)
      upload_session.update_column(:total_chunks, 0)
      chunk = upload_chunks(:upload_chunk_0)
      chunk.valid?
      expect(chunk.errors[:base]).to include("total chunks limit exceeded")
    end
  end
end