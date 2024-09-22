class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def next(attribute)
    self.class.where("#{attribute} > ?", self.send(attribute)).order("#{attribute} ASC").first || self
  end

  def prev(attribute)
    self.class.where("#{attribute} < ?", self.send(attribute)).order("#{attribute} DESC").first || self
  end

end
