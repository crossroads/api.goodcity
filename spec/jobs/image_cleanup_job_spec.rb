require "rails_helper"

RSpec.describe ImageCleanupJob, type: :job do
  let(:cloudinary_id) { "123456/folder/test.jpg" }
  let(:image) { Image.new(cloudinary_id: cloudinary_id) }

  it "should call ImageCleanupJob with image" do
    allow(Rails).to receive(:env).and_return("staging")
    expect(Cloudinary::Api).to receive(:delete_resources).
      with([image.cloudinary_id_public_id]).and_return(true)
    ImageCleanupJob.new.perform(cloudinary_id)
  end
end
