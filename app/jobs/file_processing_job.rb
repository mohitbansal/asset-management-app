class FileProcessingJob < ApplicationJob
  queue_as :default

  def perform(upload_session_id)
    upload_session = UploadSession.where(id: upload_session_id).first
    return if !upload_session
    upload_session.assemble!
  end
end