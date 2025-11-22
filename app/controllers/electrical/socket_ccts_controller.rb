module Electrical
  class SocketCctsController < ApplicationController
    include TagablesController
    before_action :set_socket_cct, only: %i[ show edit update destroy ]
    
    def index
      index_tagable
    end

    def show
      authorize @socket_cct
    end

    def new
      new_tagable
    end

    def edit
      edit_tagable
    end

    def create
      create_tagable
    end

    def update
      update_tagable
    end

    def destroy
      destroy_tagable
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

      def set_socket_cct
        @socket_cct = Electrical::SocketCct.find(params[:id])
      end

      def socket_cct_params
        params.require(:electrical_socket_cct).permit(:socket_type, :quantity, :notes,
          tag: [
            :id, :project_id, :discipline_id, :prefix, :serial,
            :suffix, :service, :stage, :notes, :tagable_type
          ])
      end
  end
end