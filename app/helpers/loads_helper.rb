module LoadsHelper
  def load_basis_translated
    Constants.electrical.load_basis.to_h{ |k, v| [ v, I18n.t("electrical.constants.load_basis.#{k}")] }
  end
end
