module ViewHelper
  def show_attribute(record, attr, type: :string, label_cols: 4, value_cols: 8, default: '-')
    label = record.class.human_attribute_name(attr)
    value = record.send(attr)
    value ||= default if default.present?
    case type
    when :string
      content_tag(:div, class: "row mb-1") do
        content_tag(:div, label + ": ", class: "col-#{label_cols} text-muted") +
        content_tag(:div, value, class: "col-#{value_cols}")
      end
    when :text
      content_tag(:div, class: "mb-1") do
        content_tag(:div, label + ": ", class: "text-muted mb-1") +
        content_tag(:div, class: "p-2 border rounded bg-light-subtle") do
          simple_format(value)
        end
      end
    when :enum_translated
      value = record.class.human_enum_name(attr, value)
      content_tag(:div, class: "row mb-1") do
        content_tag(:div, label + ": ", class: "col-#{label_cols} text-muted") +
        content_tag(:div, value, class: "col-#{value_cols}")
      end
    end
  end

  def show_text_attribute(label, value)
    content_tag(:div, class: "mb-1") do
      content_tag(:div, label, class: "text-muted small mb-1") +
      content_tag(:div, class: "p-2 border rounded bg-light-subtle") do
        value.present? ? simple_format(value) : empty_placeholder
      end
    end
  end
end