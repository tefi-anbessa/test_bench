module RolesHelper
  def role_names
    Rails.configuration.role_names.to_h{ |r| [ r, I18n.t("rolify.names.#{r}")] }
  end
end
