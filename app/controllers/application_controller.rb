class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend
  include CurrentProjectConcern
  include Devise::Controllers::StoreLocation
  include ErrorsHelper

  around_action :switch_locale
  around_action :set_time_zone
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_paper_trail_whodunnit

  # So views can fall back to a live per-record check with the same
  # {show:, edit:, destroy:} shape when a controller hasn't precomputed
  # @permissions (e.g. an orphaned record, or a caller that doesn't set it).
  helper_method :permissions_for

  # Custom error handling for trapped bad requests
  class ConflictError < StandardError; end
  rescue_from ConflictError, with: :handle_conflict
  
  rescue_from Pundit::NotAuthorizedError do |exception|
    @exception = exception
    respond_to do |format|
      format.html do
        flash[:danger] = I18n.t('pundit.unauthorized',
          action: exception.query.to_s.humanize.downcase,
          objects: exception.record&.model_name&.human&.pluralize&.downcase || 'these resources'
        )
        render 'errors/forbidden', status: :forbidden
      end
      format.json do
        render json: {
          error: I18n.t('pundit.unauthorized',
            action: exception.query.to_s.humanize.downcase,
            objects: exception.record&.model_name&.human&.pluralize&.downcase || 'these resources'
          )
        }, status: :forbidden
      end
    end
  end

  # Handle unknown formats consistently
  rescue_from ActionController::UnknownFormat do
    respond_to do |format|
      format.any { head :not_acceptable }
    end
  end


  # rescue_from ActionController::Redirecting::UnsafeRedirectError do
  #   redirect_to root_url
  # end

  def xeqq(sql) # For use in console
    results = ActiveRecord::Base.connection.exec_query(sql)
    results.presence
  end

  # Override Pundit's default user context
  def pundit_user
    ApplicationPolicy::UserContext.new(current_user, current_project)
  end

  # Helper method to prepare role assignment data for any resource
  # @param resource [ActiveRecord::Base] The resource to get roles for
  # @return [Hash] A hash of role data grouped by user
  def prepare_role_assignment_data(resource)
    return {} unless resource.persisted?
    
    resource.roles
      .joins(:users)
      .select('roles.id as role_id, roles.name as role_name, users.name as user_name, users.id as user_id')
      .order('users.name, roles.name')
      .group_by { |r| [r.user_id, r.user_name] }
      .transform_values { |roles| roles.map { |r| [r.role_name, r.role_id] } }
  end

  protected

    def after_sign_in_path_for(resource)
      # Prefer the project already remembered via session/cookie. Failing
      # that (the `||` only evaluates this when it is), auto-select when the
      # user only has exactly one project available to them at all.
      project = load_current_project || sole_available_project

      set_current_project(project)
      project ? project_path(project) : projects_path
    end

    def sole_available_project
      available_projects = ProjectPolicy::Scope.new(pundit_user, Project).resolve
      available_projects.first if available_projects.count == 1
    end

    def default_url_options
      { locale: I18n.locale }
    end

    def configure_permitted_parameters
      added_attrs = [:name, :email, :password, :password_confirmation, :remember_me]
      devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
      devise_parameter_sanitizer.permit :sign_in, keys: [:login, :password]
      devise_parameter_sanitizer.permit :account_update, keys: added_attrs
    end

    def info_for_paper_trail
      { ip: request.remote_ip, user_agent: request.user_agent, current_project_id: current_project&.id }
    end

    # Resolution order: an explicit URL locale (e.g. clicking the language
    # switcher) wins outright; otherwise fall back to the cookie it just set
    # on a previous request, then the signed-in user's stored profile
    # preference, then the app default. Whenever the URL gives an explicit
    # locale, the cookie is (re)written so it sticks on the next request that
    # doesn't - this is what lets someone switch language from the nav menu
    # without that becoming their permanent saved preference (handy for an
    # admin briefly viewing the app in another user's language). The cookie
    # carries no security weight (worst case: wrong UI language), so unlike
    # the current_project cookie it doesn't need to be signed.
    def switch_locale(&action)
      locale = (params[:locale] || cookies[:locale] || current_user&.preferred_locale || I18n.default_locale).to_sym
      locale = I18n.default_locale unless I18n.available_locales.include?(locale)
      cookies[:locale] = { value: locale, expires: 1.year.from_now } if params[:locale].present?
      I18n.with_locale(locale, &action)
    end

    # ActiveRecord always stores/queries timestamps in UTC regardless of this
    # (Rails' default_timezone is :utc) - this only affects how they're
    # *displayed* for the current request.
    def set_time_zone(&action)
      Time.use_zone(current_user&.time_zone || "UTC", &action)
    end

  private

    # Many DisciplineResourcePolicy/ProjectResourcePolicy show?/edit?/destroy?
    # implementations only ever depend on the record's own discipline/project,
    # not on the record itself - so every row sharing that discipline/project
    # gets an identical answer. Computing this once per group - instead of
    # calling policy(record) for every row in an index - avoids a Pundit
    # evaluation (and its internal role queries) per row.
    # probes_by_key: { group_key => a_record_belonging_to_that_group }
    # Returns: { group_key => { show:, edit:, destroy: } }
    def permissions_by_group(probes_by_key)
      probes_by_key.transform_values { |probe| permissions_for(probe) }
    end

    # For an index page where every row shares one identical permission answer
    # (e.g. scoped to a single project/discipline/document, or a policy that
    # doesn't vary by record at all, like SwatchPolicy) - compute it once.
    # Returns: { show:, edit:, destroy: }
    def permissions_for(probe)
      { show: policy(probe).show?, edit: policy(probe).edit?, destroy: policy(probe).destroy? }
    end

    # Scope a tagable class to the records whose tag is within the current
    # user's Tag policy scope. Tagable models have no policy of their own -
    # authorization for them always routes through TagPolicy via their
    # `tag` association - so this is how a controller gets an authorized
    # list/lookup of tagable records directly (e.g. candidate feeder cables
    # for a circuit), in place of `policy_scope(SomeTagableClass)`.
    def tagable_scope(klass)
      tag_ids = policy_scope(Tag).where(tagable_type: klass.name).select(:tagable_id)
      klass.where(id: tag_ids)
    end

    # { id => number of `model` rows whose `foreign_key` is that id }, in one
    # query - avoids a COUNT(*) per row for an index's "how many children"
    # column (e.g. tags/_row.html.erb's children, doc_types' documents,
    # cable_types' electrical_cables). Ids with zero matches are simply
    # absent from the hash, so callers should use #fetch(id, 0), not #[].
    def counts_by(model, foreign_key, ids)
      model.where(foreign_key => ids).group(foreign_key).count
    end

    def handle_conflict(exception)
      # Log security incident
      Rails.logger.warn(
        "Security: ConflictError raised - " \
        "Message: #{exception.message}, " \
        "Controller: #{controller_name}, " \
        "Action: #{action_name}, " \
        "User: #{current_user&.id}"
      )

      # Handle symbol translation
      error_message = exception.message
      if error_message.is_a?(Symbol)
        error_message = I18n.t("errors.conflict.#{error_message}", default: error_message.to_s)
      end

      respond_to do |format|
        format.html do
          flash[:alert] = error_message || I18n.t('errors.conflict.subheader')
          render 'errors/conflict', status: :conflict
        end
        format.json do
          render json: { error: error_message || I18n.t('errors.conflict.header') }, 
                status: :conflict
        end
      end
    end
end
