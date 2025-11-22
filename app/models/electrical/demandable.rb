# frozen_string_literal: true

# This concern provides functionality for models that can have a demand (replacing Load)
module Electrical
  module Demandable
    extend ActiveSupport::Concern
    included do
      # Demand association with dependent destroy
      has_one :electrical_demand, as: :demandable, class_name: 'Electrical::Demand', dependent: :destroy
      accepts_nested_attributes_for :electrical_demand
    end
  end
end
