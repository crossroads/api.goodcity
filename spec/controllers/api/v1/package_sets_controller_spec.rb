require 'rails_helper'

RSpec.describe Api::V1::PackageSetsController, type: :controller do
  let(:package_type) { create(:package_type, code: 'AFO') }
  let(:other_package_type) { create(:package_type, code: 'BBC') }
  let(:package_set) { create(:package_set, package_type_id: package_type.id) }
  let(:empty_package_set) { create(:package_set, package_type_id: package_type.id) }
  let(:unauthorized_user) { create(:user) }
  let(:parsed_body) { JSON.parse(response.body) }
  let(:authorized_user) {
    create(:user,
      :with_multiple_roles_and_permissions,
      roles_and_permissions: {
        "SomeRole" => ["can_manage_packages"]
      }
    )
  }

  before do
    touch(package_set)
    package_set.packages << create_list(:package, 3, package_set_id: package_set.id)
  end

  describe "GET #show" do
    describe "as an authorized user" do
      before { generate_and_set_token(authorized_user) }

      it "returns a 200" do
        get :show, params: { id: package_set.id }
        expect(response.status).to eq(200)
      end

      it "returns the package_set and its packages" do
        get :show, params: { id: package_set.id }
        expect(parsed_body['package_set']['id']).to eq(package_set.id)
        expect(
          parsed_body['packages'].map { |p| p['id'] }
        ).to match_array(package_set.packages.map(&:id))
      end
    end

    describe "as an unauthorized user" do
      before { generate_and_set_token(unauthorized_user) }

      it "returns a 403" do
        get :show, params: { id: package_set.id }
        expect(response.status).to eq(403)
      end
    end

    describe "as guest" do
      # TODO: Fix tests for 4XX status
      # it "returns a 401 " do
      #   get :show, params: { id: package_set.id}
      #   expect(response.status).to eq(401)
      # end
    end
  end

  describe "POST #create" do
    let(:params) { { description: 'new set', package_type_id: package_type.id} }
    let(:post_body) { { package_set: params } }

    describe "as an authorized user" do
      before { generate_and_set_token(authorized_user) }

      it "returns a 201" do
        post :create, params: post_body
        expect(response.status).to eq(201)
      end

      it "creates a new set" do
        expect {
          post :create, params: post_body
        }.to change(PackageSet, :count).by(1)

        expect(parsed_body['package_set']['description']).to eq(params[:description])
        expect(parsed_body['package_set']['package_type_id']).to eq(params[:package_type_id])
        expect(PackageSet.last.description).to eq(params[:description])
        expect(PackageSet.last.package_type_id).to eq(params[:package_type_id])
      end
    end

    describe "as an unauthorized user" do
      before { generate_and_set_token(unauthorized_user) }

      it "returns a 403" do
        post :create, params: post_body
        expect(response.status).to eq(403)
      end
    end

    describe "as guest" do
      # TODO: Fix tests for 4XX status
      # it "returns a 401 " do
      #   post :create, params: post_body
      #   expect(response.status).to eq(401)
      # end
    end
  end

  describe "PUT #update" do
    let(:params) { { package_type_id: other_package_type.id} }

    describe "as an authorized user" do
      before { generate_and_set_token(authorized_user) }

      it "succeeds in modifying the type of an empty set" do
        put :update, params: { id: empty_package_set.id, package_set: params }
        expect(response.status).to eq(200)
        expect(parsed_body['package_set']['package_type_id']).to eq(other_package_type.id)
        expect(empty_package_set.reload.package_type_id).to eq(other_package_type.id)
      end

      it "fails to modify the type of a set with packages" do
        put :update, params: { id: package_set.id, package_set: params }
        expect(response.status).to eq(422)
      end
    end

    describe "as an unauthorized user" do
      before { generate_and_set_token(unauthorized_user) }

      it "returns a 403" do
        put :update, params: { id: package_set.id, package_set: params }
        expect(response.status).to eq(403)
      end
    end

    describe "as guest" do
      # TODO: Fix tests for 4XX status
      # it "returns a 401 " do
      #   put :update, params: { id: package_set.id, package_set: params }
      #   expect(response.status).to eq(401)
      # end
    end
  end

  describe "DELETE #destroy" do
    let(:params) { { description: 'new set', package_type_id: package_type.id} }
    let(:post_body) { { package_set: params } }

    describe "as an authorized user" do
      before { generate_and_set_token(authorized_user) }

      it "returns a 200" do
        delete :destroy, params: { id: package_set.id }
        expect(response.status).to eq(200)
      end

      it "deletes the set" do
        expect {
          delete :destroy, params: { id: package_set.id }
        }.to change(PackageSet, :count).by(-1)
      end

      it "unsets the package_set_id of its packages" do
        packages = package_set.packages

        expect(packages.map(&:package_set_id).uniq).to eq([package_set.id])
        delete :destroy, params: { id: package_set.id }
        expect(packages.map(&:reload).map(&:package_set_id).uniq).to eq([nil])
      end
    end

    describe "as an unauthorized user" do
      before { generate_and_set_token(unauthorized_user) }

      it "returns a 403" do
        delete :destroy, params: { id: package_set.id }
        expect(response.status).to eq(403)
      end
    end

    describe "as guest" do
      # TODO: Fix tests for 4XX status
      # it "returns a 401 " do
      #   delete :destroy, params: { id: package_set.id }
      #   expect(response.status).to eq(401)
      # end
    end
  end
end
