class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def next(attribute = :id)
    self.class.where("#{self.class.table_name}.#{attribute} > ?", self.send(attribute)).order("#{self.class.table_name}.#{attribute} ASC").first || self
  end

  def prev(attribute = :id)
    self.class.where("#{self.class.table_name}.#{attribute} < ?", self.send(attribute)).order("#{self.class.table_name}.#{attribute} DESC").first || self
  end
  
  def self.human_enum_name(enum_name, enum_value)
    return "" if enum_value.nil?
    I18n.t("activerecord.attributes.#{self.model_name.i18n_key.to_s}.#{enum_name.to_s.pluralize}.#{enum_value.to_sym}")
  end

  def self.nilifies_blank(*attrs)
    before_validation do
      attrs.each do |attr|
        self[attr] = nil if self[attr].blank?
      end
    end
  end

end
