module RolesHelper
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
end
