module RolesHelper
  def role_names
    Constants.role.name.to_h{ |r| [ r, I18n.t("rolify.names.#{r}")] }
  end
end
