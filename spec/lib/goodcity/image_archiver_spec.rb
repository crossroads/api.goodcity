require "rails_helper"
require 'goodcity/image_archiver'

context Goodcity::ImageArchiver do

  subject { Goodcity::ImageArchiver.new }

  context "parse_cloudinary_id" do

    it do
      expect( subject.send(:parse_cloudinary_id, "1652280851/test/office_chair.jpg")).to eql( { version: "1652280851", public_id: "test/office_chair" } )
    end

    it do
      expect( subject.send(:parse_cloudinary_id, "1652280851/office_chair.jpg")).to eql( { version: "1652280851", public_id: "office_chair" } )
    end

    it do
      expect( subject.send(:parse_cloudinary_id, "1652280851/office_chair.jpg.undefined")).to eql( { version: "1652280851", public_id: "office_chair.jpg" } )
    end

  end

end