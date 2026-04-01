require 'test_helper'
require 'helpers/resource_policy_test'
module DocumentControl
  class DocTypePolicyTest < ActiveSupport::TestCase
    include ResourcePolicyTest

    def setup
      setup_resource_policy_test
      @resource = create(:document_control_doc_type, discipline: @discipline)
      @other_resource = create(:document_control_doc_type, discipline: @other_discipline)
    end

    def new_project_resource
      build(:document_control_doc_type, discipline: @discipline)
    end

    def new_other_project_resource
      build(:document_control_doc_type, discipline: @other_discipline)
    end
  end
end
