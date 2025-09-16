module BootstrapIconHelper
  # Renders a Bootstrap icon with optional size and additional options
  #
  # @param name [String] the name of the Bootstrap icon (without the 'bi-' prefix)
  # @param options [Hash] additional HTML options for the icon
  # @option options [String, Integer] :size the size of the icon (can be numeric or Bootstrap size class)
  # @option options [String] :class additional CSS classes to add to the icon
  # @option options [String] :title title attribute for the icon
  # @option options [String] :aria aria-label attribute for accessibility
  # @return [String] HTML for the Bootstrap icon
  def icon(name, **options)
    # Extract size if provided and convert to proper Bootstrap class
    size = options.delete(:size)
    size_class = case size
                 when :sm, 'sm' then 'bi-sm'
                 when :lg, 'lg' then 'bi-lg'
                 when :xl, 'xl' then 'bi-xl'
                 when :xxl, '2x' then 'bi-2x'
                 when :xxxl, '3x' then 'bi-3x'
                 when :xxxxl, '4x' then 'bi-4x'
                 when :xxxxxl, '5x' then 'bi-5x'
                 when Numeric then "bi-#{size}x"
                 end

    # Merge any additional classes with the base class
    options[:class] = ["bi", "bi-#{name}", size_class, options[:class]].compact.join(' ')
    
    # Handle aria-label for better accessibility
    aria_label = options.delete(:aria) || options.delete(:"aria-label")
    options[:aria] = { label: aria_label } if aria_label
    
    # Handle title attribute which also sets aria-label if not already set
    if (title = options.delete(:title)) && !options.dig(:aria, :label)
      options[:aria] ||= {}
      options[:aria][:label] ||= title
    end
    
    # Use the bootstrap_icon helper from the gem
    bootstrap_icon(name, **options)
  end
end
