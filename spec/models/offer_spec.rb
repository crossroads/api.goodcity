require 'rails_helper'

RSpec.describe Offer, :type => :model do

  it { should have_many(:items) }

end
