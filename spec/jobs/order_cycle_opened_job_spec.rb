# frozen_string_literal: true

require 'spec_helper'
require_relative '../../engines/dfc_provider/spec/support/authorization_helper'

RSpec.describe OrderCycleOpenedJob do
  include AuthorizationHelper

  let(:oc_opened_before) {
    create(:simple_order_cycle, orders_open_at: 1.hour.ago)
  }
  let(:oc_opened_now) {
    create(:simple_order_cycle, orders_open_at: Time.zone.now)
  }
  let(:oc_opening_soon) {
    create(:simple_order_cycle, orders_open_at: 1.minute.from_now)
  }

  it "enqueues jobs for recently opened order cycles only" do
    expect{ OrderCycleOpenedJob.perform_now }
      .to enqueue_job(OpenOrderCycleJob).with(oc_opened_now.id)
      .and enqueue_job(OpenOrderCycleJob).with(oc_opened_before.id).exactly(0).times
      .and enqueue_job(OpenOrderCycleJob).with(oc_opening_soon.id).exactly(0).times
  end
end
