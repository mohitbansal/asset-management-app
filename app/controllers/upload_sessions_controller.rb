class UploadSessionsController < ApplicationController
  skip_forgery_protection
  before_action :set_upload_session, only: [:status, :complete]

  def create
    upload_session = UploadSession.create(upload_session_params)
    if upload_session.errors.blank?
      render json: { id: upload_session.id }, status: :created
    else
      render json: { errors: upload_session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def status
    h = {
      total_chunks: @upload_session.total_chunks,
      chunk_size: @upload_session.chunk_size,
      status: @upload_session.status
    }
    if @upload_session.incomplete?
      h[:uploaded_chunks] = @upload_session.upload_chunks.order(:sequence_no).pluck(:sequence_no)
    end
    if @upload_session.success?
      h[:document_url] = Rails.application.routes.url_helpers.rails_blob_path(@upload_session.document, only_path: true)
    end
    render json: h
  end

  def complete
    @upload_session.status = :complete
    if @upload_session.save
      head :ok
    else
      render json: { errors: @upload_session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def upload_session_params
    params.permit(:byte_length, :total_chunks, :chunk_size, :content_type)
  end

  def set_upload_session
    @upload_session = UploadSession.where(:id => params[:id]).first
    head :not_found unless @upload_session
  end
end
