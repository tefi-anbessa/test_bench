# frozen_string_literal: true
class DocumentsController < ApplicationController
  include NestedResourcesController

  # GET /documents
  def index
    index_resource
    @orphans = Document.where(doc_type_id: nil)
  end

  # GET /documents/1
  def show
    show_resource
  end

  # GET /documents/new
  # Document has no direct discipline association (it's indirect, via
  # doc_type - see Document#discipline) - @discipline.documents.build isn't
  # usable (has_many :through can't build new records that way), so this
  # can't go through the generic new_resource/create_resource, unlike every
  # other NestedResourcesController consumer so far.
  def new
    # @resource kept in sync with @document - the generic setup_form calls
    # instance_variable_set(resource_var_name, @resource), which would
    # otherwise stomp @document back to nil (@resource is never set by
    # anything else on this path, since new_resource isn't used here).
    @document = @resource = Document.new(creation_discipline: @discipline)
    authorize @document, :new?
    setup_form
  end

  # POST /documents
  def create
    @document = @resource = Document.new(create_params.merge(creation_discipline: @discipline))
    authorize @document, :create?

    if @document.save
      flash[:success] = t('flash.create.notice',
        resource_name: t('activerecord.models.document.one'))
      redirect_to @document
    else
      flash[:alert] = t('flash.create.alert',
        resource_name: t('activerecord.models.document.one').downcase)
      setup_form
      render :new, status: :unprocessable_content
    end
  end

  # GET /documents/1/edit
  def edit
    edit_resource
  end

  # PATCH/PUT /documents/1
  def update
    update_resource
  end

  # DELETE /documents/1
  def destroy
    destroy_resource
  end

  private

    def index_includes(scope)
      scope.includes(doc_type: { discipline: :project })
    end

    # @discipline.documents.build (the default - see
    # NestedResourcesController#new_resource_probe) doesn't set up doc_type,
    # so the built record's own #discipline would be nil - creation_discipline
    # is how a new Document actually learns its discipline before doc_type
    # is chosen (see Document#creation_discipline).
    def new_resource_probe
      Document.new(creation_discipline: @discipline)
    end

    def setup_additional_form_data
      # Scoped to the current discipline - unscoped, this let a document get
      # created under @discipline's route while actually filing it under a
      # different doc_type's discipline (see Document#doc_type_matches_discipline).
      @doc_types = policy_scope(DocType).where(discipline: @discipline)
    end

    def create_params
      params.require(:document).permit(:doc_type_id, :title, :notes)
    end

    # Used by the generic update_resource - title/notes only, doc_type_id
    # is set once at creation and not changed on edit (matches the
    # original create_params/update_params split).
    def resource_params
      params.require(:document).permit(:title, :notes)
    end
end
