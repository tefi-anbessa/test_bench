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
end
