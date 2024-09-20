module ApplicationHelper

  # Returns the full title on a per-page basis.
  def full_title(page_title = '')
    base_title = t('app_name')
    if page_title.empty?
      base_title
    else
      page_title + " | " + base_title
    end
  end

  def flag_code(locale)
    codes = {en: :gb}
    flag_code = codes[locale] || locale
  end
end
