module NestedResourcesController
  extend ActiveSupport::Concern
  included do
    before_action :authenticate_user!
    before_action :require_project!, only: [:new, :create, :edit, :update]
    before_action :set_parent, only: %i[index new create]
    before_action :set_resource, only: [:show, :edit, :update, :destroy]
  end

  private

    # GET /projects/1/examples 
    # This method will set the resources instance variable (e.g., @motors, @switchboards)
    # in accordance with the policy scope for the resource, ransack seach params, and pagy.
    def index_resource
      authorize resource_class, :index?
      @q = scope_to_parent(policy_scope(resource_class)).ransack(params[:q])
      result = index_includes(@q.result)
      @pagy, @resources = pagy(result)
      resources_var_name = "@#{controller_name}"
      instance_variable_set(resources_var_name, @resources)
      # Resources with no parent at all (e.g. DocType/Document/Tag's own
      # globally-unscoped rows) are a separate, :none-only concept from "not
      # in the parent currently being viewed" - the including controller
      # sets its own @orphans for that when it applies; this scope is
      # already restricted to @parent, so there's nothing to split out here.
      @orphans = []
      if homogeneous_permissions?
        # Every row shares the same immediate parent, so the policy (if it
        # only depends on that, as ProjectResourcePolicy/
        # DisciplineResourcePolicy-based ones do) gives every row an
        # identical answer - compute it once instead of per row.
        probe = new_resource_probe
        @permissions = permissions_for(probe)
      else
        # :project nesting on a discipline-scoped resource spans every
        # discipline in the project - rows can have genuinely different
        # permissions (e.g. CableTypePolicy's catalog_required_role can
        # vary per discipline), so group instead of assuming one answer.
        probes = @resources.group_by { |r| r.discipline&.id }.except(nil).transform_values(&:first)
        @permissions = permissions_by_group(probes)
      end
      set_swatch
    end

    # GET /examples/1
    def show_resource
      authorize @resource, :show?
      instance_variable_set(resource_var_name, @resource)
      @neighbours = Navigator.new(scope: @scope, record: @resource).neighbours
      set_swatch
    end

    # GET /projects/1/examples/new
    def new_resource
      # Build a new resource to authorize
      @resource = @parent.public_send(resource_class.model_name.plural).build()
      after_build_hook(@resource)
      authorize @resource, :new?
      setup_form
    end

  # POST /projects/1/examples
    def create_resource
      # Build an empty resource first
      @resource = @parent.public_send(resource_class.model_name.plural).build()
      after_build_hook(@resource)
      # Assign attributes, catch invalid enum values
      begin
        @resource.assign_attributes(resource_params)
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end

      authorize @resource, :create?
      if @resource.save
        flash[:success] = t('flash.create.notice', 
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one"))
        redirect_to @resource, status: :see_other
      else
        flash.now[:alert] = t('flash.create.alert', 
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        failed_to_save
        return
      end
      
    end

    # GET /examples/1/edit 
    def edit_resource
      authorize @resource, :edit?
      setup_form
    end

    # PATCH/PUT /examples/1 
    def update_resource
      authorize @resource, :update?

      # Catch enum validation errors
      begin
        @resource.assign_attributes(resource_params)
      rescue ArgumentError => _
        # Handle invalid enum values as a conflict
        raise ApplicationController::ConflictError, :invalid_enum
      end

      if @resource.save
        flash[:success] = t('flash.update.notice', 
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one"))
        redirect_to @resource, status: :see_other
      else
        flash.now[:alert] = t('flash.update.alert', 
          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        failed_to_save
        return
      end
    end

    # DELETE /examples/1
    def destroy_resource
      authorize @resource, :destroy?
      if @resource.destroy
        flash[:success] = t('flash.destroy.notice',
                          resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one"))
        redirect_to helpers.public_send(index_path, @parent), status: :see_other
      else
        flash[:alert] = t("flash.destroy.alert",
                            resource_name: t("activerecord.models.#{resource_class.model_name.i18n_key}.one").downcase)
        redirect_back fallback_location: helpers.public_send(index_path, @parent), status: :see_other
      end
    end
    
    # False only for :project nesting on a discipline-scoped resource - the
    # one case where a single page's rows can span more than one discipline
    # (and so, potentially, more than one permission answer). Every other
    # nesting (:none included - unscoped, but only reachable for a
    # project-only resource; a discipline-scoped resource's :none index
    # isn't reachable via any real route today) shares one parent, or one
    # project, for every row.
    def homogeneous_permissions?
      !(nesting == :project && discipline_scoped_resource?)
    end

    # Override for model-specific eager-loading on the index query (e.g.
    # CableType's .includes(:cables, :detail, discipline: :project)).
    def index_includes(scope)
      scope
    end

    def set_parent
      return if nesting == :none
      return unless nesting.in?(%i[tag discipline project document issue])

      klass = nesting.to_s.classify.constantize
      @parent_var  = :"@#{nesting}"
      param = :"#{nesting}_id"

      @parent = policy_scope(klass).find_by(id: params[param])
      raise ApplicationController::ConflictError, :out_of_scope if @parent.nil?

      instance_variable_set(@parent_var, @parent)
    end

    def set_resource
      @resource = policy_scope(resource_class).find_by(id: params[:id])
      raise ApplicationController::ConflictError, :out_of_scope if @resource.nil?
      # Set the parent ivar (@discipline/@project/@tag/etc) before @scope
      # references it below - not after, which would leave @scope built
      # against a nil parent for every nesting type except :project
      # (whose ivar happens to already be populated independently
      # elsewhere in the request).
      @parent = @resource.public_send(nesting)
      @parent_var = :"@#{nesting}"
      instance_variable_set(@parent_var, @parent)
      @scope = scope_to_parent(policy_scope(resource_class))
    end

    # Restrict scope to rows belonging to @parent for the current nesting -
    # shared between a single record's Navigator scope (set_resource) and
    # the index query (index_resource), both of which need the exact same
    # restriction. :none has no parent to restrict to.
    def scope_to_parent(scope)
      return scope if nesting == :none
      case nesting
      when :project
        # No .where needed - every discipline-scoped and project-only
        # Policy::Scope already restricts to current_project, which is
        # @parent here. The join is still needed so Navigator's ORDER BY
        # can reference projects columns (e.g. ChangeManagement::Request's
        # navigator_order_sql) - .where(project: @parent) would add
        # nothing real and breaks outright for a has_one :through project
        # (e.g. CableType's, via discipline: confirmed .joins(:project)
        # alone correctly joins "projects", but the hash-condition
        # shorthand then references a bare, nonexistent "project" table).
        scope.joins(:project)
      when :discipline
        # Navigator's ORDER BY can reference projects/disciplines columns
        # (see e.g. DocType/Document.navigator_order_sql), so the scope
        # needs that join present one way or another. Some
        # discipline-scoped models reach discipline indirectly (e.g.
        # Document, via doc_type) and their own Policy::Scope already
        # provides a join via its own path - adding a second, differently
        # -shaped join to the same table makes Rails alias it, breaking
        # Navigator's raw SQL (confirmed: .where(discipline: ...) alone
        # generates a bare "discipline"."id" reference with no matching
        # FROM-clause entry for an indirect association). For those,
        # .merge with the parent's own association filters without a
        # second join. Models with a direct discipline_id column (and so
        # no join in their inherited Scope) need one added explicitly.
        if "#{resource_class}Policy".constantize.const_defined?(:Scope, false)
          scope.merge(@parent.public_send(resource_class.model_name.plural))
        else
          scope.joins(discipline: :project).where(discipline_id: @parent.id)
        end
      when :tag
        scope.joins(tag: { discipline: :project }).where(tag: @parent)
      when :document
        scope.joins(document: { discipline: :project }).where(document: @parent)
      when :issue
        scope.joins(issue: { document: { discipline: :project } }).where(issue: @parent)
      end
    end

    # Two canonical chains (see docs - swatch system rationalisation):
    # discipline-scoped resources check the discipline's own swatch field,
    # then the discipline's backing module's Base swatch, then the
    # project's swatch field, then app_theme. Project-only resources check
    # the project's swatch field, then their own module's Base swatch
    # (reached generically via resource_class.swatch, which resolves
    # through ordinary Ruby inheritance to whichever Base defines it - see
    # Electrical::Base/Instrument::Base/ChangeManagement::Base), then
    # app_theme.
    def set_swatch
      @swatch = if discipline_scoped_resource?
        @discipline&.swatch ||
          @discipline&.backing_module&.swatch ||
          @project&.swatch ||
          Swatch.find_by(name: 'app_theme')
      else
        @project&.swatch ||
          (resource_class.swatch if resource_class.respond_to?(:swatch)) ||
          Swatch.find_by(name: 'app_theme')
      end
    end

    # Whether this resource fundamentally belongs to a discipline - even
    # when the current request's nesting happens to be :project or :none
    # (a dual-scoped resource's index can be reached either way; its swatch
    # convention doesn't change because of which index view was used).
    def discipline_scoped_resource?
      if resource_class.const_defined?(:NESTED_SCOPES)
        resource_class::NESTED_SCOPES.include?(:discipline)
      else
        nesting.in?(%i[discipline tag document issue])
      end
    end

    def setup_form
      instance_variable_set(resource_var_name, @resource)
      set_swatch
      setup_additional_form_data
    end

    def failed_to_save
      # If we get here, there was a validation error preventing save
      # @resource has been set in the calling action
      return_action = @resource.persisted? ? :edit : :new
      setup_form
      respond_to do |format|
        format.html { render return_action, status: :unprocessable_content }
        format.json { render json: @resource.errors, status: :unprocessable_content }
      end
    end

    # controller_path returns the namespaced controller class, e.g. Electrical::MotorsController
    # classify.constantize converts this to a model class, e.g. Electrical::Motor
    # Use this for creating a new resource matching the calling controller 
    def resource_class
      controller_path.classify.constantize
    end

    # The resource_class provides the model_name methods, e.g. electrical_cables
    # Use index_path for redirecting to the index action of the calling controller
    def index_path
      "#{nesting}_#{resource_class.model_name.route_key}_path"
    end

    # Provide the instance variable name expected by resource forms, e.g. @cable
    def resource_var_name
      "@#{resource_class.model_name.element}"
    end

    # Override to specify model-specific form setup
    def setup_additional_form_data
      # Override in subclass for model-specific setup
    end

    # Override for setup that must happen right after a new resource is
    # built, before authorize/assign_attributes - e.g. CableType building
    # its discipline-specific detail subtype so detail_attributes in
    # resource_params has something to apply to.
    def after_build_hook(resource)
      # Override in subclass for model-specific logic
    end

    # A representative unsaved instance for the one-probe-per-page
    # permissions check (see index_resource) - override when
    # @parent.public_send(...).build isn't how this resource is really
    # built (e.g. Document, whose real parent association is indirect and
    # needs `creation_discipline:`, not a has_many-through .build).
    def new_resource_probe
      @parent ? @parent.public_send(resource_class.model_name.plural).build : resource_class.new
    end

    # Override to specify model-specific post-creation logic
    def after_create_hook(resource)
      # Override in subclass for model-specific logic (e.g., circuits creation)
    end

    # Override to specify model-specific post-update logic
    def after_update_hook(resource)
      # Override in subclass for model-specific logic
    end

    # Including class must either override this directly (returning one
    # fixed value: :tag/:discipline/:project/:document/:issue), or define
    # NESTED_SCOPES on resource_class for a resource reachable via more
    # than one parent (e.g. CableType: both discipline- and project-nested
    # index views). For the latter: :index/:new/:create routes may carry a
    # discipline_id/project_id param to resolve from, but :show/:edit/
    # :update/:destroy are flat/shallow routes with neither - for those,
    # nesting is always the resource's primary (first-declared) scope,
    # its one true direct parent, never the alternate index-only one.
    def nesting
      return @nesting if defined?(@nesting)
      unless resource_class.const_defined?(:NESTED_SCOPES)
        raise NotImplementedError, "Including class must implement nesting method"
      end
      scopes = resource_class::NESTED_SCOPES
      @nesting = if params[:id].present?
        scopes.first
      else
        scopes.find { |scope| params[:"#{scope}_id"].present? } || :none
      end
    end
end
