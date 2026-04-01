module SwatchesHelper

  def swatch_variables(swatch)
    {
      "--bg" => swatch.bg,
      "--text" => swatch.text,
      "--form-bg" => swatch.form_bg,
      "--form-field" => swatch.form_field,
      "--card-bg" => swatch.card_bg,
      "--card-header-bg" => swatch.card_header_bg,
      "--card-border" => swatch.card_border,
      "--badge-bg" => swatch.badge_bg,
      "--badge-text" => swatch.badge_text,
      "--link" => swatch.link_text,
      "--link-hover" => swatch.link_hover
    }.map { |k, v| "#{k}: #{v};" }.join(" ")
  end

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
