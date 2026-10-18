# frozen_string_literal: true
class DocTypesController < ApplicationController
  include NestedResourcesController

  # GET /discipline/:discipline_id/doc_types or GET /project/:project_id/doc_types
  # Can't use the generic index_resource - DocTypePolicy#index? needs the
  # actual Discipline/Project being indexed, not the bare class, so the
  # project-wide and discipline-scoped cases can be gated separately (see
  # DocTypePolicy#index?). Everything past that point is identical to
  # index_resource.
  def index
    authorize(@parent || DocType, :index?, policy_class: DocTypePolicy)
    @q = scope_to_parent(policy_scope(DocType)).ransack(params[:q])
    result = index_includes(@q.result)
    @pagy, @doc_types = pagy(result)
    @orphans = DocType.where(discipline_id: nil)
    @document_counts = counts_by(Document, :doc_type_id, @doc_types.map(&:id))
    if homogeneous_permissions?
      @permissions = permissions_for(new_resource_probe)
    else
      probes = @doc_types.group_by { |r| r.discipline&.id }.except(nil).transform_values(&:first)
      @permissions = permissions_by_group(probes)
    end
    set_swatch
  end

  # GET /doc_types/1
  def show
    show_resource
  end

  # GET /disciplines/:discipline_id/doc_types/new
  def new
    new_resource
  end

  # POST /disciplines/:discipline_id/doc_types
  def create
    create_resource
  end

  # GET /doc_types/1/edit
  def edit
    edit_resource
  end

  # PATCH/PUT /doc_types/1
  def update
    update_resource
  end

  # DELETE /doc_types/1
  def destroy
    destroy_resource
  end

  private

    def index_includes(scope)
      scope.includes(discipline: :project)
    end

    # DocType has a copy_from facility to allow selecting any other
    # existing doc_type as a template - template values are the base,
    # explicitly submitted values take priority. Does not cater for enum
    # checking.
    def resource_params
      permitted = params.require(:doc_type).permit(:code, :name, :description).to_h
      if params[:copy_from].present? && (template = DocType.find_by(id: params[:copy_from]))
        template.attributes.slice(*permitted.keys).merge(permitted)
      else
        permitted
      end
    end

    def setup_additional_form_data
      @copy_from_selector = DocType
        .select(:code, :name)
        .distinct
        .order(:code, :name)
    end
end
