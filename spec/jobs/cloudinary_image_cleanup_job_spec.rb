require 'rails_helper'

RSpec.describe CloudinaryImageCleanupJob, type: :job do
  let!(:image) { build :image }

  it "should call CloudinaryImageCleanupJob with image" do
    expect(Cloudinary::Api).to receive(:delete_resources).with([image.public_image_id]).and_return(true)
    CloudinaryImageCleanupJob.new.perform(image)
  end


end
