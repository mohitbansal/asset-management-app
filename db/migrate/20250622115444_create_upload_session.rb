class CreateUploadSession < ActiveRecord::Migration[8.0]
  def change
    create_table :upload_sessions do |t|
      t.integer :total_chunks
      t.integer :chunk_size
      t.string :status
      t.timestamps
    end
  end
end
