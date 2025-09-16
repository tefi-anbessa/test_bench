# Collapsible Component

A reusable collapsible component that provides smooth animations and proper ARIA attributes for accessibility.

## Features

- Smooth expand/collapse animations
- Keyboard accessible (Space/Enter to toggle)
- Proper ARIA attributes for screen readers
- Responsive design
- Configurable icons and styling
- Works with Bootstrap's collapse component

## Usage

### Basic Usage

```erb
<%= render 'components/collapsible', title: 'Section Title', id: 'unique-id' do %>
  Your collapsible content goes here
<% end %>
```

### With Initial State

```erb
<%= render 'components/collapsible', 
  title: 'Expanded by Default', 
  id: 'expanded-section',
  expanded: true do %>
  
  This content will be visible by default
<% end %>
```

### Custom Styling

```erb
<%= render 'components/collapsible', 
  title: 'Custom Styled', 
  id: 'custom-styled',
  header_class: 'bg-light',
  body_class: 'p-4' do %>
  
  Custom styled content
<% end %>
```

### Without Icon

```erb
<%= render 'components/collapsible', 
  title: 'No Icon', 
  id: 'no-icon',
  show_icon: false do %>
  
  Content without a toggle icon
<% end %>
```

## JavaScript API

The component uses a Stimulus controller (`collapsible_controller.js`) with the following features:

### Actions
- `click->collapsible#toggle` - Toggles the collapsible content

### Targets
- `icon` - The chevron icon element that rotates
- `content` - The collapsible content element

### Values
- `expanded` - Boolean indicating if the content is expanded

## CSS Classes

- `.collapsed` - Applied to the icon when content is collapsed
- `[aria-expanded="true"]` - Applied to the header when expanded
- `[aria-expanded="false"]` - Applied to the header when collapsed

## Accessibility

The component includes:
- `role="button"` on the header
- `aria-expanded` state
- `aria-controls` to associate the button with the content
- Keyboard navigation support (Space/Enter)
- Focus management

## Browser Support

- Modern browsers (Chrome, Firefox, Safari, Edge)
- IE11+ with polyfills
- Mobile browsers

## Dependencies

- Bootstrap 5.x
- Stimulus.js
- Bootstrap Icons (optional, for the chevron)
