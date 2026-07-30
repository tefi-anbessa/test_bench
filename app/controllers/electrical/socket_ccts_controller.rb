module Electrical
  class SocketCctsController < ApplicationController
    include TagablesController
    
    def index
      index_resource
    end

    def show
      show_resource
    end

    def new
      new_resource
    end

    def edit
      edit_resource
    end

    def create
      create_resource
    end

    def update
      update_resource
    end

    def destroy
      destroy_resource
    end

    private

      def tag_prefix
        "ES"  # Electrical Socket
      end

      def discipline_code
        :elec  # Electrical
      end

      def setup_additional_form_data
        # Socket circuits don't need additional form data
      end

      def resource_params
        params.require(:electrical_socket_cct).permit(:socket_type, :quantity, :notes,
          tag: [
            :discipline_id, :prefix, :serial,
            :suffix, :service, :stage, :notes, :tagable_type
          ])
      end
  end
end