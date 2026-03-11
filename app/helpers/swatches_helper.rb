module SwatchesHelper
  def container_styles(swatch)
    "background-color: #{swatch.bg}; color: #{swatch.text}"
  end

  def form_styles(swatch)
    "background-color: #{swatch.form_bg}"
  end

  def form_field_styles(swatch)
    "background-color: #{swatch.form_field}"
  end
  
  def card_styles(swatch)
    "background-color: #{swatch.card_bg}; border-color: #{swatch.card_border}"
  end

  def card_header_styles(swatch)
    "background-color: #{swatch.card_header_bg}"
  end

  def badge_styles(swatch)
    "background-color: #{swatch.badge_bg}; color: #{swatch.badge_text}"
  end

  def link_styles(swatch)
    "color: #{swatch.link_text}"
  end

  def link_hover_styles(swatch)
    "color: #{swatch.link_hover}"
  end

  def color_preview_with_hex(color_value, size: 30)
    return "" unless color_value.present?
    "<div class=\"rounded border me-2\" style=\"width: #{size}px; height: #{size}px; background-color: #{color_value};\" title=\"#{color_value}\"></div>"
  end
end
