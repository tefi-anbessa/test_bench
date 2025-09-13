module RolesHelper
  def setup_role_assignment(resource = nil)
    # Initialize required instance variables with defaults
    @resource_types = []
    @grouped_role_names = {}
    @users = User.none  # Default to empty relation
    @roles = Role.none  # Default to empty relation
    @grouped_roles = []
    @role = Role.new
    @resource_type = nil
    @resource_id = nil
    @role_name = nil
    @user_id = nil

    # Set up drop down menus for resource_type, role_name, and user
    begin
      @resource_types = [
        [t('rolify.role_types.global'), '']
      ] + (Rolify.resource_types || []).map do |r|
        [r.constantize.model_name.human, r] rescue [r, r]
      end
      
      @grouped_role_names = role_names
      @users = User.all

      # Set scope 
      if resource.present? && resource.persisted?
        @roles = resource.roles.includes(:users)
        @resource_type = resource.class.name
        @resource_id = resource.id
      else
        @roles = Role.includes(:users)
      end
      
      @grouped_roles = prepare_roles_for_display(@roles)
      
    rescue => e
      Rails.logger.error "Error in setup_role_assignment: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def role_names
    grouped_roles = {}
    
    # Add global roles with group label
    if Constants.roles.global_roles.any?
      grouped_roles[I18n.t('rolify.groups.global')] = 
        Constants.roles.global_roles.map { |r| [I18n.t("rolify.names.#{r}", default: r.to_s.humanize), r] }
    end
    
    # Add functional roles with group label
    if Constants.roles.functional_roles.any?
      grouped_roles[I18n.t('rolify.groups.functional')] = 
        Constants.roles.functional_roles.map { |r| [I18n.t("rolify.names.#{r}", default: r.to_s.humanize), r] }
    end
    
    # Add resource-specific roles with group labels
    if Constants.roles.respond_to?(:resources) && Constants.roles.resources.any?
      Constants.roles.resources.each do |resource, roles|
        next if roles.blank?
        group_name = I18n.t("rolify.groups.resource") % {resource: resource.to_s.humanize}
        grouped_roles[group_name] = roles.map { |r| [I18n.t("rolify.names.#{r}", default: r.to_s.humanize), r] }
      end
    end
    
    grouped_roles
  end

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
