require 'rails_helper'

RSpec.describe UploadChunk, type: :model do
  it { should have_one_attached(:document) }
  it { should belong_to(:upload_session) }
  it { should validate_presence_of(:document) }
  it { should validate_presence_of(:sequence_no) }
  it { should validate_uniqueness_of(:sequence_no).scoped_to(:upload_session_id) }

end