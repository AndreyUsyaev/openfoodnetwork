# frozen_string_literal: true

require "swagger_helper"
require DfcProvider::Engine.root.join("spec/spec_helper")

describe "SuppliedProducts", type: :request, swagger_doc: "dfc-v1.7/swagger.yaml",
                             rswag_autodoc: true do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) { create(:distributor_enterprise, owner: user) }
  let!(:product) { create(:simple_product, supplier: enterprise ) }
  let!(:variant) { product.variants.first }

  before { login_as user }

  path "/api/dfc-v1.7/enterprises/{enterprise_id}/supplied_products" do
    parameter name: :enterprise_id, in: :path, type: :string

    let(:enterprise_id) { enterprise.id }

    post "Create SuppliedProduct" do
      consumes "application/json"
      produces "application/json"

      # This parameter is required but I want to write a spec which doesn't
      # supply it. I couldn't do it with rswag when requiring it.
      parameter name: :supplied_product, in: :body, required: false, schema: {
        example: {
          '@context': "http://static.datafoodconsortium.org/ontologies/context.json",
          '@id': "http://test.host/api/dfc-v1.7/enterprises/6201/supplied_products/0",
          '@type': "dfc-b:SuppliedProduct",
          'dfc-b:name': "Apple",
          'dfc-b:description': "A delicious heritage apple",
          'dfc-b:hasType': "dfc-pt:non-local-vegetable",
          'dfc-b:hasQuantity': {
            '@type': "dfc-b:QuantitativeValue",
            'dfc-b:hasUnit': "dfc-m:Gram",
            'dfc-b:value': 3.0
          },
          'dfc-b:alcoholPercentage': 0.0,
          'dfc-b:lifetime': "",
          'dfc-b:usageOrStorageCondition': "",
          'dfc-b:totalTheoreticalStock': 0.0
        }
      }

      response "400", "bad request" do
        run_test!
      end

      response "204", "success" do
        let(:supplied_product) do |example|
          example.metadata[:operation][:parameters].first[:schema][:example]
        end

        it "creates a variant" do |example|
          expect { submit_request(example.metadata) }
            .to change { enterprise.supplied_products.count }.by(1)

          variant = Spree::Variant.last
          expect(variant.name).to eq "Apple"
          expect(variant.unit_value).to eq 3
        end
      end
    end
  end

  path "/api/dfc-v1.7/enterprises/{enterprise_id}/supplied_products/{id}" do
    parameter name: :enterprise_id, in: :path, type: :string
    parameter name: :id, in: :path, type: :string

    let(:enterprise_id) { enterprise.id }

    get "Show SuppliedProduct" do
      produces "application/json"

      response "200", "success" do
        let(:id) { variant.id }

        run_test! do
          expect(response.body).to include variant.name
        end
      end

      response "404", "not found" do
        let(:id) { other_variant.id }
        let(:other_variant) { create(:variant) }

        run_test!
      end
    end

    put "Update SuppliedProduct" do
      consumes "application/json"

      parameter name: :supplied_product, in: :body, schema: {}

      let(:id) { variant.id }
      let(:supplied_product) do
        JSON.parse(DfcProvider::Engine.root.join("spec/support/patch_supplied_product.json").read)
      end

      response "401", "unauthorized" do
        before { login_as nil }

        run_test!
      end

      response "204", "success" do
        it "updates a variant" do |example|
          expect {
            submit_request(example.metadata)
            variant.reload
          }.to change { variant.description }.to("DFC-Pesto updated")
            .and change { variant.unit_value }.to(17)
        end
      end
    end
  end
end
