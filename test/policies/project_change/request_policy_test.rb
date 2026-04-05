require 'test_helper'
require 'helpers/resource_policy_test'
module ProjectChange
  class RequestPolicyTest < ActiveSupport::TestCase
    include ResourcePolicyTest

    def setup
      setup_resource_policy_test
      @resource = create(:change_request, discipline: @discipline)
      @other_resource = create(:change_request, discipline: @other_discipline)
    end

    def new_project_resource
      build(:change_request, discipline: @discipline)
    end

    def new_other_project_resource
      build(:change_request, discipline: @other_discipline)
    end

    # All setup and tests have been abstracted to ResourcePolicyTest and PolicyTestHelpers.
  end
end
