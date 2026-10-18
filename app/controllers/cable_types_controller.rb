class CableTypesController < ApplicationController
  include NestedResourcesController

  # GET /cable_types or /cable_types.json
  # Can't use the generic index_resource - CableTypePolicy#index? needs the
  # actual Discipline/Project being indexed, not the bare class, so the
  # project-wide and discipline-scoped cases can be gated separately (see
  # CableTypePolicy#index?). Everything past that point is identical to
  # index_resource.
  def index
    authorize(@parent || CableType, :index?, policy_class: CableTypePolicy)
    @q = scope_to_parent(policy_scope(CableType)).ransack(params[:q])
    result = index_includes(@q.result)
    @pagy, @cable_types = pagy(result)
    if homogeneous_permissions?
      @permissions = permissions_for(new_resource_probe)
    else
      probes = @cable_types.group_by { |r| r.discipline&.id }.except(nil).transform_values(&:first)
      @permissions = permissions_by_group(probes)
    end
    set_swatch
  end

  # GET /cable_types/1 or /cable_types/1.json
  def show
    show_resource
  end

  # GET /cable_types/new
  def new
    new_resource
  end

  # POST /cable_types or /cable_types.json
  def create
    create_resource
  end

  # GET /cable_types/1/edit
  def edit
    edit_resource
  end

  # PATCH/PUT /cable_types/1 or /cable_types/1.json
  def update
    update_resource
  end

  # DELETE /cable_types/1 or /cable_types/1.json
  def destroy
    destroy_resource
  end

  private

    def index_includes(scope)
      # :detail (delegated_type, so polymorphic) needs its own .preload -
      # scope_to_parent's explicit .joins for :discipline/:project nesting
      # would otherwise force Rails to eager_load every included
      # association (including :detail) via LEFT OUTER JOIN, which raises
      # for a polymorphic association.
      scope.includes(:cables, discipline: :project).preload(:detail)
    end

    # A cable type's detail subtype is fixed by its discipline, not chosen
    # on the form - build the right concrete type up front so the nested
    # detail_attributes in resource_params have something to apply to.
    def after_build_hook(resource)
      detail_class = @discipline.cable_type_detail_class
      raise ApplicationController::ConflictError, :out_of_scope if detail_class.nil?
      resource.detail = detail_class.new
    end

    def setup_additional_form_data
      @csa_select = Constants.cable.conductor_csa
    end

    # Only allow a list of trusted parameters through. detail_attributes
    # is the union of every discipline's own detail fields - only the
    # ones belonging to this cable type's actual detail_type are ever
    # meaningfully submitted, since the form only renders those.
    def resource_params
      params.require(:cable_type).permit(
        :primary_role, :conductor_material, :groups, :construction, :csa,
        :insulation, :bedding, :armour, :sheath, :bedding_od, :overall_od,
        :temperature_rating, :voltage_rating, :fire_protection,
        :environment_protection, :applicable_standard, :notes,
        detail_attributes: [:neutral_csa, :earth_csa, :individual_screen, :overall_screen, :twist_pitch]
      )
    end
end
