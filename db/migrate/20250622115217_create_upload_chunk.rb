class CreateUploadChunk < ActiveRecord::Migration[8.0]
  def change
    create_table :upload_chunks do |t|
      t.integer :sequence_no
      t.references :upload_session
      t.timestamps
      t.index [:sequence_no, :upload_session_id], unique: true
    end
  end
end
