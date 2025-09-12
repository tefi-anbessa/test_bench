module ApplicationHelper
  include Pagy::Frontend
  
  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = t('app_name')
    if page_title.empty?
      base_title
    else
      page_title + " | " + base_title
    end
  end

  # Returns a country symbol for a given language symbol, to help with flag icons.
  # Can be controversial!
  def flag_code(locale)
    codes = {en: :gb, km: :kh}
    flag_code = codes[locale] || locale
  end
  
  # Check if current user is an admin
  def admin?
    current_user&.has_role?(:admin)
  end

  # Maps flash message types to Bootstrap alert classes
  #
  # @param flash_type [String, Symbol] The flash message type (e.g., :success, :danger, :notice, :alert)
  # @return [String] The corresponding Bootstrap alert class
  #
  # @example
  #   bootstrap_alert_class(:success) # => 'success'
  #   bootstrap_alert_class('danger') # => 'danger'
  #   bootstrap_alert_class(:notice)  # => 'success'
  #   bootstrap_alert_class(:alert)   # => 'danger'
  #   bootstrap_alert_class(:error)   # => 'danger'
  #   bootstrap_alert_class(:warning) # => 'warning'
  #   bootstrap_alert_class(:info)    # => 'info'
  #   bootstrap_alert_class(:other)   # => 'other'
  def bootstrap_alert_class(flash_type)
    case flash_type.to_s.downcase.to_sym
    when :success, :notice
      'success'
    when :danger, :alert, :error
      'danger'
    when :warning
      'warning'
    when :info
      'info'
    else
      # Default to the original flash type if no match is found
      flash_type.to_s
    end
  end
end
