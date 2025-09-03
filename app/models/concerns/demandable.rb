# frozen_string_literal: true

# This concern provides functionality for models that can have a demand (replacing Load)
module Demandable
  extend ActiveSupport::Concern
  included do
    # Demand association with dependent destroy
    has_one :demand, as: :demandable, dependent: :destroy
    accepts_nested_attributes_for :demand
  end
end
