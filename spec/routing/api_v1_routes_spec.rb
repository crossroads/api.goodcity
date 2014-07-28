require 'rails_helper'

describe "routes for API v1" do

  it "routes for offers" do
    expect( get: "/api/v1/offers.json" ).to route_to ( {controller: "api/v1/offers", action: 'index', format: 'json'} )
    expect( get: "/api/v1/offers/1.json" ).to route_to ( {controller: "api/v1/offers", action: 'show', id: '1', format: 'json'} )
  end

end
