class TagsController < ApplicationController
  include NestedResourcesController
  include Importable

  # import/create_import need the same @discipline/@project resolution as
  # index/new/create, and set_swatch for their own view - neither is in
  # NestedResourcesController's own before_action lists, since it has no
  # notion of the Importable actions. Registering set_parent/require_project!
  # again under a second before_action with a different `only:` doesn't add
  # a second, independent entry - it replaces the concern's own one
  # (confirmed via the actual callback chain), silently breaking it for
  # index/new/create/edit/update. Distinctly-named wrappers avoid that.
  before_action :set_parent_for_import, only: %i[import create_import parent_search]
  before_action :require_project_for_import!, only: %i[import create_import parent_search]
  before_action :set_swatch, only: %i[import create_import]

  # GET /tags
  def index
    index_resource
    @orphans = Tag.where(discipline_id: nil)
    @children_counts = counts_by(Tag, :parent_id, @tags.map(&:id))
  end

  # GET /tags/1 or /tags/1.json
  def show
    show_resource
  end

  # GET /tags/new
  def new
    new_resource
  end

  # POST /tags or /tags.json
  def create
    create_resource
  end

  # GET /tags/1/edit
  def edit
    edit_resource
  end

  # PATCH/PUT /tags/1 or /tags/1.json
  def update
    update_resource
  end

  # DELETE /tags/1 or /tags/1.json
  def destroy
    destroy_resource
  end

  # GET /disciplines/1/tags/parent_search - remote search for the Tom
  # Select-enhanced parent field on the tag form (see
  # app/javascript/controllers/tom_select_controller.js). Project-wide, not
  # discipline-scoped - a parent tag can legitimately be in a different
  # discipline, same as the plain-select version this replaced.
  def parent_search
    authorize Tag, :index?
    tag = params[:tag_id].present? ? Tag.find_by(id: params[:tag_id]) : Tag.new
    candidates = tag.prospective_parents(policy_scope(Tag)).includes(:discipline)
    if params[:q].present?
      term = "%#{Tag.sanitize_sql_like(params[:q])}%"
      candidates = candidates.references(:discipline)
        .where("tags.full_tag ILIKE :term OR tags.service ILIKE :term OR disciplines.code ILIKE :term", term: term)
    end
    candidates = candidates.order(:discipline_id, :full_tag).limit(20)
    # long_label (discipline code + tag, see Tag#long_label) rather than bare
    # full_tag - the dropdown needs to show discipline code and service
    # description alongside the tag itself, not just the tag in isolation.
    render json: candidates.as_json(only: [:id, :service], methods: [:long_label])
  end

  private

    def set_parent_for_import
      set_parent
    end

    def require_project_for_import!
      require_project!
    end

    def index_includes(scope)
      scope.includes(:parent, discipline: :project)
    end

    # Tag's Navigator deliberately spans the whole project, not just this
    # tag's own discipline - prev/next browses every tag in the project,
    # unlike CableType/DocType/Document, whose Navigator is confined to one
    # discipline. Can't use the generic set_resource, which would narrow
    # @scope to just @discipline.
    def set_resource
      @resource = policy_scope(Tag).find_by(id: params[:id])
      raise ApplicationController::ConflictError, :out_of_scope if @resource.nil?
      @parent = @discipline = @resource.discipline
      @scope = policy_scope(Tag).joins(discipline: :project)
    end

    def setup_additional_form_data
      @safe_tagable_types = Tag.safe_tagable_types
      @schema = @discipline.schema_for_form.with_indifferent_access
      @parts = @tag.prefix_parts
    end

    def resource_params
      params.require(:tag).permit(*Tag::IMPORTABLE_ATTRIBUTES)
    end

    # === Importable concern hooks (see app/controllers/concerns/importable.rb) ===

    def importer_key
      "tags"
    end

    def authorize_import!
      # A discipline-scoped import already knows which discipline, so it can
      # be authorized precisely upfront - a project-wide import can't be
      # (see Importable#authorize_import!'s own comment).
      authorize @discipline.tags.build, :import? if @discipline.present?
    end
end
