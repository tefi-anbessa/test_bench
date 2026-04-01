require 'test_helper'
require_relative '../../helpers/resource_policy_test'
module DocumentControl
  class SourceFormatPolicyTest < ActiveSupport::TestCase
    include ResourcePolicyTest

    def setup
      setup_resource_policy_test
      @resource = create(:document_control_source_format)
      @other_resource = create(:document_control_source_format)
    end

    def new_project_resource
      build(:document_control_source_format)
    end

    def new_other_project_resource
      build(:document_control_source_format)
    end

    # All setup and tests have been abstracted to ResourcePolicyTest and PolicyTestHelpers.
  end
end
