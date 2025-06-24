class FileProcessingJob < ApplicationJob
  queue_as :default

  def perform(upload_session_id)
    upload_session = UploadSession.where(id: upload_session_id).first
    return if !upload_session
    Rails.logger.info "assembling files ..."
    upload_session.assemble!
    Rails.logger.info "files assembled"

    Rails.logger.info "scanning virus.."
    upload_session.scan_virus!
    Rails.logger.info "virus scan complete ..."
  end
end