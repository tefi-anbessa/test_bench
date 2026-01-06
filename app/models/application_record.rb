class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def next(attribute = :id)
    self.class.where("#{attribute} > ?", self.send(attribute)).order("#{attribute} ASC").first || self
  end

  def prev(attribute = :id)
    self.class.where("#{attribute} < ?", self.send(attribute)).order("#{attribute} DESC").first || self
  end
  
  def self.human_enum_name(enum_name, enum_value)
    return "" if enum_value.nil?
    I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{enum_value.to_sym}")
  end
end
