require 'rails_helper'

describe "routes for API v1" do

  it do
    expect( get: "/api/v1/offers.json" ).to route_to ( {controller: "api/v1/offers", action: 'index', format: 'json'} )
    expect( get: "/api/v1/offers/1.json" ).to route_to ( {controller: "api/v1/offers", action: 'show', id: '1', format: 'json'} )
    expect( get: "/api/v1/donor_conditions.json" ).to route_to ( {controller: "api/v1/donor_conditions", action: 'index', format: 'json'} )
    expect( get: "/api/v1/donor_conditions/1.json" ).to route_to ( {controller: "api/v1/donor_conditions", action: 'show', id: '1', format: 'json'} )
  end

  it "routes the goods-types editor's containment member actions" do
    base = { controller: "api/v1/package_types", id: "4", format: "json" }
    expect(post: "/api/v1/package_types/4/subpackage_types").to route_to(base.merge(action: "add_subpackage_type"))
    expect(patch: "/api/v1/package_types/4/subpackage_types/9").to route_to(base.merge(action: "set_subpackage_default", child_id: "9"))
    expect(put: "/api/v1/package_types/4/subpackage_types/9").to route_to(base.merge(action: "set_subpackage_default", child_id: "9"))
    expect(delete: "/api/v1/package_types/4/subpackage_types/9").to route_to(base.merge(action: "remove_subpackage_type", child_id: "9"))
    expect(delete: "/api/v1/package_types/4").to route_to(base.merge(action: "destroy"))
  end

end
