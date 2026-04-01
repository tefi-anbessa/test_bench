require 'test_helper'
require 'helpers/resource_policy_test'
module DocumentControl
  class IssuePolicyTest < ActiveSupport::TestCase
    include ResourcePolicyTest

    def setup
      setup_resource_policy_test
      @resource = create(:document_control_issue, document: create(:document, discipline: @discipline))
      @other_resource = create(:document_control_issue, document: create(:document, discipline: @other_discipline))
    end

    def new_project_resource
      build(:document_control_issue, document: create(:document, discipline: @discipline))
    end

    def new_other_project_resource
      build(:document_control_issue, discipline: @other_discipline)
    end

    # All setup and tests have been abstracted to ResourcePolicyTest and PolicyTestHelpers.
  end
end
