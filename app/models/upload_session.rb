class UploadSession < ApplicationRecord
  enum :status, incomplete: "incomplete", complete: "complete", assembled: "assembled", default: :incomplete
  
  has_one_attached :document
  
  has_many :upload_chunks

  validates :total_chunks, :chunk_size, presence: true

  validate :validate_chunks_size_on_complete, if: :complete?

  after_save :process_file, if: [:saved_change_to_status?, :complete?]

  def validate_chunks_size_on_complete
    if upload_chunks.count != total_chunks
      errors.add(:base, "session can't be complete because uploaded chunks are not equal to total chunks")
    end
  end

  def assemble!
    return if !complete?
    blobs = upload_chunks.order(:sequence_no).map { |ch| ch.document.blob }
    filename = blobs.last.filename
    new_blob = ActiveStorage::Blob.compose(blobs, filename: filename)
    document.attach(new_blob)
    self.status = :assembled
    self.save!
  end

  def process_file
    FileProcessingJob.perform_later(id)
  end
end