# frozen_string_literal: true

module NavigationHelper
  ACTION_CONFIG = {
    delete: {
      bs_color: "danger",
      bs_icon: "trash"
    },
    edit: {
      bs_color: "warning",
      bs_icon: "pencil-square"
    },
    new: {
      bs_color: "primary",
      bs_icon: "plus-square-fill"
    },
    link: {
      bs_color: "primary",
      bs_icon: "link"
    },
    show: {
      bs_color: "info",
      bs_icon: "eye"
    },
    show_project: {
      bs_color: "info",
      bs_icon: "layers"
    },
    show_discipline: {
      bs_color: "info",
      bs_icon: "collection"
    },
    show_tag: {
      bs_color: "info",
      bs_icon: "tag"
    },
    show_document: {
      bs_color: "info",
      bs_icon: "file"
    },
    previous: {
      bs_color: "secondary",
      bs_icon: "box-arrow-in-left"
    },
    next: {
      bs_color: "secondary",
      bs_icon: "box-arrow-in-right"
    },
    down: {
      bs_color: "info",
      bs_icon: "box-arrow-in-down-right"
    },
    up: {
      bs_color: "info",
      bs_icon: "box-arrow-in-up-left"
    },
    index_link: {
      bs_color: "info",
      bs_icon: "eye"
    },
    index: {
      bs_color: "info",
      bs_icon: "list-columns-reverse"
    },
    index_project: {
      bs_color: "info",
      bs_icon: "layers"
    },
    index_discipline: {
      bs_color: "info",
      bs_icon: "collection"
    },
    children: {
      bs_color: "info",
      bs_icon: "list-columns-reverse"
    }
  }.freeze

  def nav_button(action:, path: nil, record: nil, icon_only: false)
    config = ACTION_CONFIG[action] || {}

    path = 
      case action
      when :show, :show_project, :show_discipline, :show_tag, :show_document, :down, :up, :previous, :next, :delete, :index_link
        record
      else
        path
      end
    
    label =
      case action
      when :new
        [I18n.t("actions.new"),
        record.present? ? I18n.t("activerecord.models.#{record.model_name.i18n_key}.one") : ''].join(" ")
      when :link
        I18n.t("actions.link", resource: record.present? ? 
        I18n.t("activerecord.models.#{record.model_name.i18n_key}.one", default: record.model_name.human) : 
        I18n.t("show.resource"))
      when :edit
        I18n.t("actions.edit")
      when :delete
        I18n.t("actions.delete")
      when :previous, :next, :show, :index
        I18n.t("actions.#{action}")
      when :up, :down
        I18n.t("actions.#{action}", model: record.present? ? 
        I18n.t("activerecord.models.#{record.model_name.i18n_key}.one", default: record.model_name.human) : 
        I18n.t("show.resource"))
      when :index_link
        record.try(:label)
      when :index_discipline
        record.discipline.name
      when :index_project
        record.project.code
      when :show_discipline
        record.name
      when :show_project
        record.code
      end

    help_text =
      case action
      when :index, :index_discipline, :index_project
        [record.present? ? I18n.t("activerecord.models.#{record.model_name.i18n_key}.other") : '', I18n.t("actions.index")].join(" ")
      when :index_link
        [I18n.t("actions.show"), label].join(" ")
      when :show_project
        [I18n.t("actions.show"), record.code].join(" ")
      when :show_discipline
        [I18n.t("actions.show"), record.name].join(" ")
      else
        if record
          [label, record.try(:label)].compact.join(": ")
        else
          label
        end
      end

    nav_button_html(
      action: action,
      path: path,
      label: label,
      help_text: help_text,
      bs_color: config[:bs_color],
      bs_icon: config[:bs_icon],
      icon_only: icon_only,
      bs_size: "sm"
    )
  end

  def nav_button_html(action:, path:, label:, help_text:,
                      bs_color:, bs_icon:, icon_only:, bs_size:)
    disabled = path.nil?
    classes = [
      "mb-1",
      "btn",
      "btn-#{bs_size}",
      "btn-outline-#{bs_color}",
      ("icon-link" if icon_only),
      ("disabled" if disabled)
    ].compact.join(" ")

    if disabled
      return content_tag :button,
        class: classes,
        disabled: true,
        title: help_text,
        aria: { label: help_text, disabled: true } do
          button_face(bs_icon, label, icon_only)
        end
    end
    case action
    when :delete
      button_to path,
        method: :delete,
        class: classes,
        form: { class: "d-inline" },
        data: { turbo_confirm: [help_text, t('actions.delete_sure')].join(". ") },
        title: help_text,
        aria: { label: help_text } do
        button_face(bs_icon, label, icon_only)
      end
    else
      link_to path,
        class: classes,
        title: help_text,
        aria: { label: help_text } do
          button_face(bs_icon, label, icon_only)
        end
    end
  end

  def button_face(icon, label, icon_only = false)
    if icon_only
      bs_icon(icon)
    else
      safe_join([
        bs_icon(icon),
        content_tag(:span, label, class: "d-none d-lg-inline ms-1")
      ])
    end
  end

  # Use nav_link for show links only, no content actions. Returns nothing for nil record.
  def nav_link(action:, record: nil, icon_only: false, **opts)
    config = ACTION_CONFIG[action] || {}
    text = [t("actions.jump_to", model: record&.model_name.human), record.label].join(": ")
    classes = [
      "btn",
      "btn-sm",
      "btn-outline-#{config[:bs_color]}",
      ("icon-link" if icon_only)
    ].compact.join(" ")

    if record.present?
      content_tag(:div, class: "row mb-1") do
        link_to polymorphic_path(record),
          class: classes,
          aria: { label: text },
          title: text do
            button_face(config[:bs_icon], text, icon_only)
          end
      end
    end
  end

  # Use index_link for links from index views. The helper shows a minimal label outside the icon button for compactness.
  def index_link(action:, path: nil, record: nil, **opts)
    config = ACTION_CONFIG[action] || {}
    path ||= record
    
    label =
      case action
      when :new, :link
        [I18n.t("actions.new"),
          record.present? ? 
          I18n.t("activerecord.models.#{record.model_name.i18n_key}.one") : 
          I18n.t("show.resource")
        ].join(" ")
      when :edit
        [I18n.t("actions.edit"), record&.try(:label)].join(" ")
      when :delete
        [I18n.t("actions.delete"), record&.try(:label)].join(" ")
      when :show, :previous, :next, :show_tag, :show_document
        record&.try(:label)
      when :up, :down
        I18n.t("activerecord.models.#{record&.model_name.i18n_key}.one", default: action.to_s)
      when :show_discipline
        record&.try(name)
      when :show_project
        record&.try(code)
      when :children
        opts.delete(:count)
      else
        record&.try(:label)
      end

    help_text = [I18n.t("actions.#{action}", default: action.to_s), label].join(" ")
    if path.present?
      index_link_html(path: path, label: label, help_text: help_text, bs_icon: config[:bs_icon], bs_color: config[:bs_color])
    else
      content_tag(:span, I18n.t("index.unassigned"))
    end
  end

  def index_link_html(path:, label:, help_text:, bs_icon:, bs_color: "secondary")
    disabled = path.nil?

    classes = [
      "icon-link",
      "link-#{bs_color}",
      "link-offset-0",
      "link-underline-opacity-0",
      "link-underline-opacity-0-hover",
      "text-decoration-none",
      "px-1",
      "rounded",
      ("disabled" if disabled)
    ].compact.join(" ")

    content = safe_join([
      bs_icon(bs_icon),
      content_tag(:span, label, class: "ms-1")
    ])

    if disabled
      content_tag :span,
        content,
        class: classes,
        title: help_text,
        aria: { label: help_text, disabled: true }
    else
      link_to path,
        class: classes,
        title: help_text,
        aria: { label: help_text } do
          content
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
      # without translation. The id text is. used by cards to place an id on the block for the collapsible controller.
      # Tests need to be aware of which mode is being used.
    # If no partial is found, a link to the associated record is discplayed.
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
end
