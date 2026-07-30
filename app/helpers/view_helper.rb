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
    when :string, :enum, :integer
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
    when :decimal
      # Accepts the following options:
      # :scale - if present it sets the decimal places to match the db, defaults to 2 if not provided.
      # :precision is ignored for display purposes
      # :units - string
      # :si - if true will display units with SI prefix and scale the number
      scale = options.delete(:scale) || 2
      units = options.delete(:units)
      si = options.delete(:si)
      if units.present? 
        if si
          value_part = format_number(value.to_d, precision: scale, significant: false, units: units)
        else
          value_part = [value.to_d, units].join(' ')
        end
      else
        value_part = number_to_human(value.to_d, precision: scale, significant: false)
      end
        content_tag(:div, class: "row mb-1") do
          content_tag(:div, label + ": ", class: "col-#{label_cols} text-muted") +
          content_tag(:div, value_part, class: "col-#{value_cols}")
      end
    when :float
      # Accepts the following options:
      # :precision is significant digits, defaults to 4
      # :units, string
      # :si - if true will display units with SI prefix and scale the number
      precision = options.delete(:precision) || 4
      units = options.delete(:units)
      si = options.delete(:si)
      if units.present? 
        if si
          value_part = format_number(value.to_f, precision: precision, significant: true, units: units)
        else
          value_part = [value.to_f, units].join(' ')
        end
      else
        value_part = number_to_human(value.to_f, precision: precision, significant: true)
      end
        content_tag(:div, class: "row mb-1") do
          content_tag(:div, label + ": ", class: "col-#{label_cols} text-muted") +
          content_tag(:div, value_part, class: "col-#{value_cols}")
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
        content_tag(:div, I18n.l(value, format: :default), class: "col-#{value_cols}")
      end
    when :date
      content_tag(:div, class: "row mb-1") do
        content_tag(:div, label + ": ", class: "col-#{label_cols} text-muted") +
        content_tag(:div, I18n.l(value.to_date, format: :default), class: "col-#{value_cols}")
      end
    end
  end

  def show_association(object, association, header: nil)
    # Abstracted display of dropdown collapsible card for associated records on show view.
    # Expecting object and association variables, accepts header selection, see below. 
    #
    # This method resolves the provided association. 
    # If the association results in a record, it looks for a partial named _card in the record's class' views. 
    # If a partial is found it is rendered.
      # To cater for different types of associations, the card header text is derived as follows:
      # If the caller provides variable header as either :model or :association, the symbol determines the header label.
      #   :model looks for a translation of the record's class name, defaults to class.model_name.human.
      #   :association looks for a translation of the passed association as an attribute of the passed object, defaults to no translation.
      # If header is not present:
      #   For polymorphic associations, the call to render the card passes the translated model name rather than the provided association,
      #   as most polymorphic association names are internal constructs (e.g. tagable, demandable) not meant for UI. 
      #   For other associations, the call to render the card looks for a translation of the association name as an attribute of the passed object.
      # Note that the header text is forwarded as the context variable to the card partial. 
      # The method also forwards id text, following the same path as the header text but sending the associtation or element name,
      # without translation. The id text is used by cards to place an id on the block for the collapsible controller.
      # Tests need to be aware of which mode is being used.
    # If no partial is found, a link to the associated record is displayed.
    # If the assocation is valid but no associated record is found, unassigned message is displayed, 
    # with label as translation of the association name.
    # If the association is not valid, an invalid message is displayed, with the provided association name.
    header ||= :none
    if object.respond_to?(association)
      record = object.send(association)
      if record.present?
        partial = "#{record.model_name.collection}/card"
        if lookup_context.exists?(partial, [], true)
          # Show a collapsible card for the associated object. 
          case header
          when :model
            # Try to translate the model name of the associated record, default to rails human method. 
            associated = t("activerecord.models.#{record.model_name.i18n_key}.one",
                default: record.class.model_name.human)
            id_text = record.model_name.element
          when :association
            # Set label text to attribute translation, if it exists, otherwise use association without translation. 
            associated = t("activerecord.attributes.#{object.model_name.i18n_key}.#{association}", 
                default: association.to_s.humanize)
            id_text = association
          else
            if object.class.reflect_on_association(association).polymorphic?
              # Default to the model name of the associated record. 
              associated = t("activerecord.models.#{record.model_name.i18n_key}.one",
                  default: record.class.model_name.human)
              id_text = record.model_name.element
            else
              # Set label text to attribute translation, if it exists, otherwise use association without translation. 
              associated = t("activerecord.attributes.#{object.model_name.i18n_key}.#{association}", 
                  default: association.to_s.humanize)
              id_text = association
            end
          end
          render partial, object: record, context: associated, id: id_text
        else
          config = ACTION_CONFIG[:show] || {}
          # No card available for this type, show a link to the object. 
          label = object.class.human_attribute_name(association)
          path = begin
            polymorphic_path([record])
          rescue NoMethodError, ActionController::UrlGenerationError
            '#'
          end
          disabled = path.nil?
          classes = [
            "col-8",
            "btn",
            "btn-sm",
            "btn-outline-#{confic[bs_color]}",
            ("disabled" if disabled)
          ].compact.join(" ")
          content_tag(:div, class: "row mb-2") do
            content_tag(:div, label, class: "col-4 col-form-label text-muted")
            link_to path,
              class: classes,
              aria: { label: text },
              title: text do
                button_face(config[:bs_icon], text)
              end
          end
        end
      else
        # No record present, show unassigned 
        label = t("activerecord.attributes.#{object.model_name.i18n_key}.#{association}",
          default: association.to_s.humanize)
        text = t('show.unassigned', model: label)
        content_tag(:div, class: "row mb-2") do
          content_tag(:div, label, class: "col-4 col-form-label text-muted")
          content_tag(:div, text, class: "col-8")
        end
      end
    else
      # Invalid association
      label = t("activerecord.attributes.#{object.model_name.i18n_key}.#{association}", 
        default: association.to_s.humanize)
      text = t('show.invalid', model: association.to_s)
      content_tag(:div, class: "row mb-2") do
        content_tag(:div, label, class: "col-4 col-form-label text-muted")
        content_tag(:div, text, class: "col-8")
      end
    end
  end

  def index_attribute(record, attr, type: :string, **options)
    value = record.send(attr)
    case type
    when :association
      index_link(action: :show, record: value)
    when :string, :enum, :integer
      value
    when :text
      content_tag(:span, title: value) do
        truncate(strip_tags(value.to_s), length: 20)
      end
    when :enum_translated
      record.class.human_enum_name(attr, value)
    when :decimal
      # Accepts the following options:
      # :scale - if present it sets the decimal places to match the db, defaults to 2 if not provided.
      # :precision is ignored for display purposes
      # :units - string
      # :si - if true will display units with SI prefix and scale the number
      scale = options.delete(:scale) || 2
      units = options.delete(:units)
      si = options.delete(:si)
      if units.present? 
        if si
          format_number(value.to_d, precision: scale, significant: false, units: units)
        else
          [value.to_d, units].join(' ')
        end
      else
        number_to_human(value.to_d, precision: scale, significant: false)
      end
    when :float
      # Accepts the following options:
      # :precision is significant digits, defaults to 4
      # :units, string
      # :si - if true will display units with SI prefix and scale the number
      precision = options.delete(:precision) || 4
      units = options.delete(:units)
      si = options.delete(:si)
      if units.present? 
        if si
          format_number(value.to_f, precision: precision, significant: true, units: units)
        else
          [value.to_f, units].join(' ')
        end
      else
        number_to_human(value.to_f, precision: precision, significant: true)
      end
    when :boolean
      boolean_icon(value)
    when :date
      I18n.l value.to_date, format: :short
    when :datetime, :time, :timestamp
      I18n.l value, format: :short
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