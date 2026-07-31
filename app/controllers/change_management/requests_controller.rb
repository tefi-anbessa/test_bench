# frozen_string_literal: true
module ChangeManagement
  class RequestsController < ApplicationController
    include NestedResourcesController

    # GET change_management/requests
    def index
      index_resource
    end

    # GET change_management/requests/1
    def show
      show_resource
    end

    # GET change_management/requests/new
    def new
      new_resource
    end

    # POST change_management/requests
    def create
      create_resource
    end

    # GET change_management/requests/1/edit
    def edit
      edit_resource
    end

    # PATCH/PUT change_management/requests/1
    def update
      update_resource
    end

    # DELETE change_management/requests/1
    def destroy
      destroy_resource
    end

    private

      def nesting
        :project
      end

      def setup_additional_form_data
        @disciplines = policy_scope(Discipline)
        .select('disciplines.id, disciplines.label, disciplines.name')
        .order('disciplines.label ASC')
        set_swatch
      end

      def resource_params
        params.require(:change_management_request)
        .permit(:title, :reason, :summary, :duration)
      end
  end
end
