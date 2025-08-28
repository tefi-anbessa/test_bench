module RolesHelper
  def role_names
    roles = []
    roles += Constants.roles['global_roles'] || []
    roles += Constants.roles['functional_roles'] || []
    roles.uniq.to_h { |r| [r.to_sym, I18n.t("rolify.names.#{r}", default: r.to_s.humanize)] }
  end
end
