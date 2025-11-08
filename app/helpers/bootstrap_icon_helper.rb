module BootstrapIconHelper
  def bs_icon(name, options = {})
    options = {
      width: '1rem',
      height: '1rem',
      fill: 'currentColor'
    }.merge(options)
    
    # Remove any existing bi- prefix to prevent duplication
    icon_name = name.to_s.gsub(/^bi-/, '')
    
    # Use the original bootstrap_icon method
    bootstrap_icon(icon_name, options)
  end
end
