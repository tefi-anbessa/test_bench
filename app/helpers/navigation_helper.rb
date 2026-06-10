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
    previous: {
      bs_color: "secondary",
      bs_icon: "box-arrow-in-left"
    },
    next: {
      bs_color: "secondary",
      bs_icon: "box-arrow-in-right"
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
    }
}.freeze

  def nav_button(action:, path: nil, record: nil, icon_only: false)
    config = ACTION_CONFIG[action] || {}

    # :show, :previous, :next, :delete use record as path
    path = 
      case action
      when :show, :show_project, :show_discipline, :previous, :next, :delete
        record
      else
        path
      end
    
    label =
      case action
      when :new
        [I18n.t("actions.new"),
        record.present? ? I18n.t("activerecord.models.#{record.model_name.i18n_key}.one") : ''].join(" ")
      when :edit
        I18n.t("actions.edit")
      when :delete
        I18n.t("actions.delete")
      when :previous, :next, :show, :index
        I18n.t("actions.#{action}")
      when :index_discipline
        record.discipline.name
      when :show_discipline
        record.name
      when :index_project
        record.project.code
      when :show_project
        record.code
      end

    help_text =
      case action
      when :index, :index_discipline, :index_project
        [record.present? ? I18n.t("activerecord.models.#{record.model_name.i18n_key}.other") : '', I18n.t("actions.index")].join(" ")
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
end