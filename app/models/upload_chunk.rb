class UploadChunk < ApplicationRecord
  has_one_attached :document

  belongs_to :upload_session
  validates :sequence_no, presence: true, uniqueness: { scope: :upload_session_id }
  validates :document, presence: true

  validate :ensure_chunk_size_within_limit, if: -> { document.present? && upload_session }
  validate :ensure_total_chunks_within_limit, if: [:upload_session]

  private

  def ensure_chunk_size_within_limit
    if document.blob.byte_size > upload_session.chunk_size
      errors.add(:document, "size exceeds maximum chunk size")
    end
  end

  def ensure_total_chunks_within_limit
    if upload_session.upload_chunks.count >= upload_session.total_chunks
      errors.add(:base, "total chunks limit exceeded")
    end
  end
end
