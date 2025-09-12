module BootstrapIconHelper
  def icon(name, options = {})
    options = {
      width: '1em',
      height: '1em',
      fill: 'currentColor'
    }.merge(options)
    
    # Remove any existing bi- prefix to prevent duplication
    icon_name = name.to_s.gsub(/^bi-/, '')
    
    # Use the original bootstrap_icon method
    bootstrap_icon(icon_name, options)
  end
end
