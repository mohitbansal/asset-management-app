require 'rails_helper'

RSpec.describe UploadSession, type: :model do
  fixtures :upload_sessions, :upload_chunks, "active_storage/attachments", "active_storage/blobs"

  it { should have_many(:upload_chunks) }
  it { should have_one_attached(:document) }
  it { should validate_inclusion_of(:content_type).in_array(['image/png', 'image/jpeg', 'video/mp4'])}
  it { should validate_numericality_of(:chunk_size).is_less_than_or_equal_to(5.megabytes).is_greater_than(0) }
  it { should validate_numericality_of(:total_chunks).is_less_than_or_equal_to(1000).is_greater_than(0) }

  it "validates chunks size on complete" do
    upload_session = UploadSession.new(status: :complete, total_chunks: 8)
    upload_session.valid?
    expect(upload_session.errors[:base]).to include("session can't be complete because uploaded chunks are not equal to total chunks")
  end

  it "does not validate chunks size when not complete" do
    upload_session = UploadSession.new(status: :incomplete, total_chunks: 8)
    expect(upload_session).to_not receive(:validate_chunks_size_on_complete)
    upload_session.valid?
  end

  context "after_save" do
    context "when status changed to complete" do
      it "triggers process_file" do
        upload_session = upload_sessions(:test_upload_session)
        upload_session.update_column(:status, "incomplete")

        expect(upload_session).to receive(:process_file).once
        upload_session.status = "complete"
        upload_session.save
      end
    end
  end

  describe "#process_file" do
    it "enqueue file processing job" do
      upload_session = upload_sessions(:test_upload_session)
      expect(FileProcessingJob).to receive(:perform_later).with(upload_session.id)
      upload_session.process_file
    end
  end

  describe "#assemble!" do
    it "assembles chunks into single file" do
      upload_session = upload_sessions(:test_upload_session) 
      upload_session.assemble!
      expect(upload_session.document.byte_size).to eq(file_fixture("test.png").size)
      expect(upload_session.assembled?).to be true
    end
  end

  describe '#scan_virus!' do
    context "when all chunks are assembled" do
      it "calls ClamAV to scan for viruses" do
        upload_session = upload_sessions(:assembled_session)
        expect(MockClamAv).to receive(:safe?).once
        upload_session.scan_virus!
      end
      context "when ClamAV returns true" do
        before do
          allow(MockClamAv).to receive(:safe?).and_return(true)
        end

        it "sets status as success" do
          upload_session = upload_sessions(:assembled_session)
          upload_session.scan_virus!
          expect(upload_session.success?).to be true
        end

      end

      context "when ClamAV returns false" do
        before do
          allow(MockClamAv).to receive(:safe?).and_return(false)
        end

        it "sets status as scan failure" do
          upload_session = upload_sessions(:assembled_session)
          upload_session.scan_virus!
          expect(upload_session.success?).to be false
        end
      end
    end
  end

end