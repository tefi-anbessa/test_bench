# Override rails default i18n_key to use dots instead of double colons for namespaced models.
# This is required because activerecord model translations have been revised to use key separators
# instead of file separators (which were causing numerous problems.)
module ActiveModel
  module Naming
    def i18n_key
      @name.to_s.gsub("::", ".").underscore
    end
  end
end