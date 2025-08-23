module PageSizeable
  extend ActiveSupport::Concern
  
  DEFAULT_PAGE_SIZES = [10, 25, 50, 100].freeze
  DEFAULT_PAGE_SIZE = 20  # Changed to match the actual default in the application
  
  included do
    helper_method :page_size
  end
  
  private
  
  def page_size
    @page_size ||= begin
      # First check for per_page in params
      if params[:per_page].present?
        size = params[:per_page].to_i
        size = self.class::DEFAULT_PAGE_SIZE unless size.in?(self.class::DEFAULT_PAGE_SIZES)
      else
        # Fall back to cookie or default
        size = (cookies.signed[:per_page] || self.class::DEFAULT_PAGE_SIZE).to_i
      end
      
      # Ensure the size is one of the allowed values
      size = self.class::DEFAULT_PAGE_SIZE unless size.in?(self.class::DEFAULT_PAGE_SIZES)
      
      # Store in cookie if user accepts cookies
      if cookies[:cookies_accepted] == 'true'
        cookies.signed[:per_page] = {
          value: size,
          expires: 1.year.from_now,
          secure: Rails.env.production?,
          httponly: true
        }
      end
      
      size
    end
  end
  
  def pagy_with_page_size(collection, vars = {})
    # Get the page size from params, cookie, or default
    @page_size = if params[:per_page].present?
                  size = params[:per_page].to_i
                  size.in?(self.class::DEFAULT_PAGE_SIZES) ? size : self.class::DEFAULT_PAGE_SIZE
                else
                  (cookies.signed[:per_page] || self.class::DEFAULT_PAGE_SIZE).to_i
                end
    
    # Store in cookie if user accepts cookies
    if cookies[:cookies_accepted] == 'true'
      cookies.signed[:per_page] = {
        value: @page_size,
        expires: 1.year.from_now,
        secure: Rails.env.production?,
        httponly: true
      }
    end
    
    # Force the items per page in the pagination
    # Ensure we're using the correct items count and merging any other pagy options
    pagy_opts = { items: @page_size, page: params[:page] || 1 }.merge(vars)
    
    # Debug output
    Rails.logger.debug "[PAGY] Using page size: #{@page_size} for #{controller_name}##{action_name}"
    
    # Handle Ransack search results
    if collection.respond_to?(:result)
      pagy(collection.result, **pagy_opts)
    else
      pagy(collection, **pagy_opts)
    end
  end
end
