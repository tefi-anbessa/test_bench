class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def next
    self.class.where("id > ?", id).order("id ASC").first || self.class.first
# self.class.where("#{attribute} > ?", self."#{attribute}").order("#{attribute} ASC").first || self
  end

  def prev
    self.class.where("id < ?", id).order("id DESC").first || self.class.last
  end

end
