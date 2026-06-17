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

  def form_field(form, attr, type: :string, label_cols: 4, value_cols: 8, **options)
    label = form.object.class.human_attribute_name(attr)

    field = case type
    when :string
      form.text_field(attr, class: "form-control", **options)

    when :text
      form.text_area(attr, class: "form-control", rows: 3, **options)

    when :select
      # expects :collection in options
      collection = options.delete(:collection) || []
      form.select(attr, collection, { include_blank: true }, class: "form-select")

    when :enum
      values = form.object.class.send(attr.to_s.pluralize).keys
      collection = values.map { |v| [v, v] }
      form.select(attr, collection, { include_blank: true }, class: "form-select")

    when :enum_translated
      values = form.object.class.send(attr.to_s.pluralize).keys
      collection = values.map { |v| [form.object.class.human_enum_name(attr, v), v] }
      form.select(attr, collection, { include_blank: true }, class: "form-select")

    else
      raise ArgumentError, "Unknown field type: #{type}"
    end

    content_tag(:div, class: "row mb-2") do
      content_tag(:div, label, class: "col-#{label_cols} col-form-label text-muted") +
      content_tag(:div, field, class: "col-#{value_cols}")
    end
  end

  def form_tag_prefix_element(schema, key, selected, label_cols: 4, value_cols: 8, required: false, data_update: true)
    label = t("activerecord.attributes.tag.prefix_parts.#{key}", default: key.to_s.humanize)
    options = schema[key].map do |option, value| 
      text = [option, t("activerecord.attributes.tag.prefix_parts.#{key.to_s.pluralize}.#{option}", default: value)].join(": ")
      [text, option]
    end
    blank = required ? t("form.required") : t("form.optional")
    if data_update
      field = select_tag(key, options_for_select(options, selected), 
          { include_blank: blank, class: "form-select", 
          data: { action: "change->tag-prefix#updatePrefix", tag_prefix_target: key.to_s.camelize(:lower) } })
    else
      field = select_tag(key, options_for_select(options, selected), 
          { include_blank: blank, class: "form-select" } )
    end
    content_tag(:div, class: "row mb-2") do
      content_tag(:div, label, class: "col-#{label_cols} col-form-label text-muted") +
      content_tag(:div, field, class: "col-#{value_cols}")
    end
  end
end