class UploadSession < ApplicationRecord
  MAX_CHUNKS = 1000
  MAX_CHUNK_SIZE = 5.megabytes
  enum :status, { incomplete: "incomplete", complete: "complete", assembled: "assembled", scan_failure: "scan_failed", success: "success" }, default: :incomplete
  
  has_one_attached :document do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100], preprocessed: true
  end
  
  has_many :upload_chunks

  validates :chunk_size, numericality: { less_than_or_equal_to: MAX_CHUNK_SIZE, greater_than: 0 }
  validates :total_chunks, numericality: { less_than_or_equal_to: MAX_CHUNKS, greater_than: 0 }
  validates :content_type, inclusion: { in: %w(image/jpeg image/png video/mp4) }
  
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

  def scan_virus!
    return if !assembled?
    document.open do |file|
      if MockClamAv.safe?(document.blob)
        self.status = :success
      else
        self.status = :scan_failure
      end
      self.save!
    end
  end

  def process_file
    FileProcessingJob.perform_later(id)
  end
end
