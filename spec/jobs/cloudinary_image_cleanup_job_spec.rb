require "rails_helper"

RSpec.describe CloudinaryImageCleanupJob, type: :job do
  let!(:image) { build :image }
  let!(:cloudinary_id) { image.public_image_id }

  it "should call CloudinaryImageCleanupJob with image" do
    allow(Rails).to receive(:env).and_return("staging")
    expect(Cloudinary::Api).to receive(:delete_resources).
      with([cloudinary_id]).and_return(true)
    CloudinaryImageCleanupJob.new.perform(cloudinary_id)
  end
end
