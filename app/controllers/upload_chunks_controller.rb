class UploadChunksController < ApplicationController
  before_action :set_upload_session
  def create
    chunk = @upload_session.upload_chunks.create(chunk_params)
    if chunk.errors.blank?  
      head :created
    else
      render json: { errors: chunk.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_upload_session
    @upload_session = UploadSession.where(id: params[:upload_session_id]).first
    head :not_found unless @upload_session
  end

  def chunk_params
    params.permit(:sequence_no, :document)
  end
end