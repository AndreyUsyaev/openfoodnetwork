# frozen_string_literal: true

require 'spec_helper'

module Spree
  RSpec.describe Taxon do
    let(:taxon) { Spree::Taxon.new(name: "Ruby on Rails") }

    let(:e) { create(:supplier_enterprise) }
    let(:t1) { create(:taxon) }
    let(:t2) { create(:taxon) }

    describe "finding all supplied taxons" do
      let!(:p1) {
        create(:simple_product, primary_taxon_id: t1.id, supplier_id: e.id)
      }

      it "finds taxons" do
        expect(Taxon.supplied_taxons).to eq(e.id => Set.new([t1.id]))
      end
    end

    describe "finding distributed taxons" do
      let!(:oc_open) {
        create(:open_order_cycle, distributors: [e], variants: [p_open.variants.first])
      }
      let!(:oc_closed) {
        create(:closed_order_cycle, distributors: [e], variants: [p_closed.variants.first])
      }
      let!(:p_open) { create(:simple_product, primary_taxon: t1) }
      let!(:p_closed) { create(:simple_product, primary_taxon: t2) }

      it "finds all distributed taxons" do
        expect(Taxon.distributed_taxons(:all)).to eq(e.id => Set.new([t1.id, t2.id]))
      end

      it "finds currently distributed taxons" do
        expect(Taxon.distributed_taxons(:current)).to eq(e.id => Set.new([t1.id]))
      end
    end

    describe "touches" do
      let!(:taxon1) { create(:taxon) }
      let!(:taxon2) { create(:taxon) }
      let!(:product) { create(:simple_product, primary_taxon_id: taxon1.id) }
      let(:variant) { product.variants.first }

      it "is touched when assignment of primary_taxon on a variant changes" do
        expect do
          variant.update(primary_taxon: taxon2)
        end.to change { taxon2.reload.updated_at }
      end
    end
  end
end
