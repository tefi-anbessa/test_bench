module RolesHelper
  
  # returns user_context for given user and project
  def user_context(user, project)
    ApplicationPolicy::UserContext.new(user, project || @project)
  end

  def setup_role_assignment(resource = nil)
    # Initialize required instance variables with defaults
    @resource_types = []
    @grouped_role_names = {}
    @role_names_by_resource_type = {}
    @users = User.none  # Default to empty relation
    @roles = Role.none  # Default to empty relation
    @grouped_roles = []
    @role = Role.new(resource: resource)
    @resource_type = nil
    @resource_id = nil
    @role_name = nil
    @user_id = nil

    # Set up drop down menus for resource_type, role_name, and user
    begin
      @resource_types = [
        [t('rolify.role_types.global'), '']
      ] + (Rolify.resource_types.uniq || []).map do |r|
        [r.constantize.model_name.human, r] rescue [r, r]
      end
      @grouped_role_names = role_names(resource, current_user)
      @role_names_by_resource_type = role_names_by_resource_type(resource, current_user)
      @users = User.all

      # Set scope 
      if resource.present? && resource.is_a?(ActiveRecord::Base) && resource.persisted?
        # Resource instance scoped roles
        @roles = resource.roles.includes(:users)
        @resource_type = resource.class.name
        @resource_id = resource.id
      elsif resource.present? && resource.is_a?(Class) && resource < ActiveRecord::Base
        # Resource wide roles
        @roles = Role.where(resource_type: resource.name, resource_id: nil).includes(:users)
      elsif resource.blank?
        # Global roles
        @roles = Role.includes(:users)
      else
        # Fallback
        @roles = Role.none
      end
      
      @grouped_roles = prepare_roles_for_display(@roles)
      
    rescue => e
      Rails.logger.error "Error in setup_role_assignment: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  # Returns grouped role names for dropdown.
  # If resource is provided, returns roles for that resource type and user permissions.
  # If resource is nil, returns global and resource wide roles.
  # Only roles the user is allowed to grant are included (prevents attempted privilege escalation).
  def role_names(resource = nil, user = nil)
    grouped_roles = {}

    allowed_global_role_options(resource, user).then do |options|
      grouped_roles[I18n.t('rolify.groups.global')] = options if options.any?
    end

    each_allowed_resource_role_options(resource, user) do |res_type, options|
      grouped_roles[I18n.t("rolify.groups.resource") % {resource: res_type.to_s.humanize}] = options
    end

    grouped_roles
  end

  # Same role names as role_names, but keyed by the raw resource_type string
  # (matching the role[resource_type] select's own option values, e.g.
  # "Project", with "" for global) instead of a translated group label.
  # Used to give the resource-type-selector Stimulus controller everything
  # it needs to repopulate the role[name] select client-side, without a
  # server round-trip, while still only ever offering roles this user is
  # actually allowed to grant.
  def role_names_by_resource_type(resource = nil, user = nil)
    by_type = {}

    by_type[''] = allowed_global_role_options(resource, user)

    each_allowed_resource_role_options(resource, user) do |res_type, options|
      by_type[res_type.to_s.classify] = options
    end

    by_type
  end

  private

  # [[label, value], ...] for whichever global roles this user may grant.
  def allowed_global_role_options(resource, user)
    return [] unless resource.nil? && Constants.roles.global_roles.any?

    user ||= current_user
    Constants.roles.global_roles.select do |r|
      role = Role.new(name: r, resource: nil)
      RolePolicy.new(user_context(user, nil), role).create?
    end.map { |r| [I18n.t("rolify.names.#{r}", default: r.to_s.humanize), r] }
  end

  # Yields (res_type, [[label, value], ...]) for each resource type with at
  # least one role this user may grant - shared by role_names and
  # role_names_by_resource_type so the permission-filtering logic (and the
  # resource_instance/resource_wide selection) lives in exactly one place.
  def each_allowed_resource_role_options(resource, user)
    return unless Constants.roles.respond_to?(:resources) && Constants.roles.resources.any?

    user ||= current_user
    resources_to_check = if resource.present?
                           current_type = resource.is_a?(ActiveRecord::Base) ?
                             resource.class.name.underscore.to_sym :
                             resource.to_s.underscore.to_sym
                           Constants.roles.resources.slice(current_type)
                         else
                           Constants.roles.resources
                         end

    resources_to_check.each do |res_type, roles|
      next if roles.blank?

      resource_for_policy = if resource.present? && resource.is_a?(ActiveRecord::Base)
                              resource
                            else
                              res_type.to_s.safe_constantize
                            end

      # roles is {resource_instance: [...], resource_wide: [...]} (see
      # config/constants/role.yml). A known instance can only end up with a
      # resource_instance role; with no instance yet chosen, offer both -
      # Role's own validation decides which actually apply once submitted.
      candidate_names = if resource.present? && resource.is_a?(ActiveRecord::Base)
                          Array(roles[:resource_instance])
                        else
                          (Array(roles[:resource_instance]) + Array(roles[:resource_wide])).uniq
                        end

      allowed_roles = candidate_names.select do |r|
        role = Role.new(name: r, resource: resource_for_policy)
        RolePolicy.new(user_context(user, resource_for_policy), role).create?
      end

      next if allowed_roles.blank?

      yield res_type, allowed_roles.map { |r| [I18n.t("rolify.names.#{r}", default: r.to_s.humanize), r] }
    end
  end

  public

  def prepare_roles_for_display(roles_scope)
    # Process roles into a flat structure with user details
    sorted_roles = []
    roles_scope.includes(:users).each do |role|
      role.users.each do |user|
        resource_label = if role.resource_id.blank?
                          "-"
                        elsif role.resource&.respond_to?(:label)
                          role.resource.label
                        else
                          role.resource_id
                        end
        
        resource_type = role.resource_type.presence || "-"
        
        sorted_roles << {
          id: role.id,
          user_id: user.id,
          resource_type: resource_type,
          resource_label: resource_label,
          role_name: role.name,
          user_name: user.name,
          role: role
        }
      end
    end

    # Sort by resource_type, resource_label, and role_name
    sorted_roles.sort_by! { |h| [h[:resource_type], h[:resource_label], h[:role_name]] }

    # Group the sorted roles
    group_roles(sorted_roles)
  end

  def group_roles(roles)
    grouped = {}
    
    roles.each do |role|
      rt = role[:resource_type]
      grouped[rt] ||= {}
      rl = role[:resource_label]
      grouped[rt][rl] ||= {}
      rn = role[:role_name]
      grouped[rt][rl][rn] ||= []
      grouped[rt][rl][rn] << role[:user_name]
    end
    
    grouped
  end

  # For use in the _role_assignment partial
  def grouped_roles_for_resource(resource)
    return {} unless resource.present?
    
    roles = resource.roles.includes(:users)
    prepare_roles_for_display(roles)
  end
end
