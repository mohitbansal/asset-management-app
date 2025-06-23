class UploadChunk < ApplicationRecord
  has_one_attached :document

  belongs_to :upload_session
  validates :sequence_no, presence: true, uniqueness: { scope: :upload_session_id }
  validates :document, presence: true
end
