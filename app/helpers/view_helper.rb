module ViewHelper
  def show_attribute(record, attr, type: :string, label_cols: 4, value_cols: 8, **options)
    label = record.class.human_attribute_name(attr)
    value = record.send(attr)
    case type
    when :association
      if value.present?
        value_section = index_link(action: :show, record: value)
      else
        value_section = I18n.t("index.unassigned")
      end
      content_tag(:div, class: "row mb-1") do
        content_tag(:span, label + ": ", class: "col-#{label_cols} text-muted") +
        content_tag(:span, value_section, class: "col-#{value_cols}")
      end
    when :string, :enum, :integer, :decimal
      value ||= options.delete(:default)
      content_tag(:div, class: "row mb-1") do
        content_tag(:div, label + ": ", class: "col-#{label_cols} text-muted") +
        content_tag(:div, value, class: "col-#{value_cols}")
      end
    when :text
      value ||= options.delete(:default)
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
    when :float
      # Accepts the following options:
      # :precision, defaults to 4
      # :units, expects base SI unit string
      precision = options.delete(:precision) || 4
      units = options.delete(:units)
      if units.present?
        units_hash = {  mili: "m#{units}",
                        micro: "μ#{units}",
                        nano: "n#{units}",
                        pico: "p#{units}",
                        femto: "f#{units}",
                        unit: "#{units}",
                        thousand: "k#{units}",
                        million: "M#{units}",
                        trillion: "G#{units}",
                        quadrillion: "P#{units}"
                      }
        content_tag(:div, class: "row mb-1") do
          content_tag(:div, label + ": ", class: "col-#{label_cols} text-muted") +
          content_tag(:div, number_to_human(value, precision: precision, units: units_hash), class: "col-#{value_cols}")
        end
      else
        content_tag(:div, class: "row mb-1") do
          content_tag(:div, label + ": ", class: "col-#{label_cols} text-muted") +
          content_tag(:div, number_to_human(value, precision: precision), class: "col-#{value_cols}")
        end
      end
    when :boolean
      # Accepts options for true_label and false_label
      true_label = options.delete(:true_label) || I18n.t("show.true")
      false_label = options.delete(:false_label) || I18n.t("show.false")
      content_tag(:div, class: "row mb-1") do
        safe_join([
          content_tag(:div, "#{label}:", class: "col-#{label_cols} text-muted"),
          content_tag(:div, class: "col-#{value_cols}") do
            if value
              content_tag(:span, class: "text-success", title: true_label, aria: { label: true_label }) do
                safe_join([
                  bs_icon("check-square-fill", width: '1.5rem', height: '1.5rem'),
                  content_tag(:span, true_label, class: "visually-hidden")
                ])
              end
            else
              content_tag(:span, class: "text-muted", title: false_label, aria: { label: false_label }) do
                safe_join([
                  bs_icon("x-square"),
                  content_tag(:span, false_label, class: "visually-hidden")
                ])
              end
            end
          end
        ])
      end
    when :datetime
      content_tag(:div, class: "row mb-1") do
        content_tag(:div, label + ": ", class: "col-#{label_cols} text-muted") +
        content_tag(:div, value, class: "col-#{value_cols}")
      end
    when :date
      content_tag(:div, class: "row mb-1") do
        content_tag(:div, label + ": ", class: "col-#{label_cols} text-muted") +
        content_tag(:div, I18n.l(value.to_date, format: :default), class: "col-#{value_cols}")
      end
    end
  end

  def index_attribute(record, attr, type: :string, **options)
    value = record.send(attr)
    case type
    when :association
      index_link(action: :show, record: value)
    when :string, :enum, :integer, :decimal
      value
    when :text
      content_tag(:span, title: value) do
        truncate(strip_tags(value.to_s), length: 20)
      end
    when :enum_translated
      record.class.human_enum_name(attr, value)
    when :float
      # Accepts the following options:
      # :precision, defaults to 4
      # :units, expects base SI unit string
      precision = options.delete(:precision) || 4
      units = options.delete(:units)
      if units.present?
        units_hash = {  mili: "m#{units}",
                        micro: "μ#{units}",
                        nano: "n#{units}",
                        pico: "p#{units}",
                        femto: "f#{units}",
                        unit: "#{units}",
                        thousand: "k#{units}",
                        million: "M#{units}",
                        trillion: "G#{units}",
                        quadrillion: "P#{units}"
                      }
          number_to_human(value, precision: precision, units: units_hash)
      else
        number_to_human(value, precision: precision)
      end
    when :boolean
      boolean_icon(value)
    end
  end

  # Stand alone version of boolean attribute
  def boolean_icon(value, true_label: "Yes", false_label: "No")
    if value
      content_tag(:span,
        class: "text-success",
        title: true_label,
        aria: { label: true_label }) do
          safe_join([
            bs_icon("check-circle-fill"),
            content_tag(:span, true_label, class: "visually-hidden")
          ])
        end
    else
      content_tag(:span,
        class: "text-muted",
        title: false_label,
        aria: { label: false_label }) do
          safe_join([
            bs_icon("x-circle"),
            content_tag(:span, false_label, class: "visually-hidden")
          ])
        end
    end
  end

  def form_field(form, attr, type: :string, label_cols: 4, control_cols: 8, **options)

    field = case type
    when :string
      form.text_field(attr, class: "form-control", 
        label_col: "col-sm-#{label_cols}", control_col: "col-sm-#{control_cols}", **options)

    when :text
      form.text_area(attr, class: "form-control", rows: 3, layout: :vertical, **options)

    when :number
      # include range, step and optional units in options
      units = options.delete(:units)
      form.number_field(attr, class: "form-control", 
        label_col: "col-sm-#{label_cols}", control_col: "col-sm-#{control_cols}", append: units, **options)

    when :select
      # expects :collection in options
      collection = options.delete(:collection) || []
      # expects :required in options
      blank = options.delete(:required) ? t("form.required") : t("form.optional")
      form.select(attr, collection, { include_blank: blank }, 
        label_col: "col-sm-#{label_cols}", control_col: "col-sm-#{control_cols}", class: "form-select", **options)

    when :enum
      # expects :required in options
      blank = options.delete(:required) ? t("form.required") : t("form.optional")
      values = form.object.class.send(attr.to_s.pluralize).keys
      collection = values.map { |v| [v, v] }
      form.select(attr, collection, { include_blank: blank }, class: "form-select")

    when :enum_translated
      # expects :required in options
      blank = options.delete(:required) ? t("form.required") : t("form.optional")
      values = form.object.class.send(attr.to_s.pluralize).keys
      collection = values.map { |v| [form.object.class.human_enum_name(attr, v), v] }
      form.select(attr, collection, { include_blank: blank }, 
        label_col: "col-sm-#{label_cols}", control_col: "col-sm-#{control_cols}", class: "form-select")

    when :boolean
      form.form_group(attr, label: { text: form.object.class.human_attribute_name(attr) }) do
        content_tag(:div, class: "d-flex align-items-center") do
          form.check_box(attr, skip_label: true)
        end
      end

    when :colour, :color
      form.color_field(attr, class: "form-control", 
        label_col: "col-sm-#{label_cols}", control_col: "col-sm-#{control_cols}", **options)

    else
      raise ArgumentError, "Unknown field type: #{type}"
    end

    content_tag(:div, class: "row mb-1") do
      content_tag(:div, field)
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