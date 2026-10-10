module UsersHelper
  # Renders the user's uploaded avatar, or a plain initials circle when none
  # is attached - replaces the old Gravatar-based helper, which depended on
  # a third-party fetch (to secure.gravatar.com) succeeding for every row of
  # every index that showed a user.
  def avatar_for(user, size: 40)
    if user.avatar.attached?
      image_tag user.avatar, alt: user.name, class: "rounded-circle",
        style: "width: #{size}px; height: #{size}px; object-fit: cover;"
    else
      content_tag :div, user.initials,
        class: "rounded-circle d-inline-flex align-items-center justify-content-center bg-secondary text-white",
        style: "width: #{size}px; height: #{size}px; font-size: #{(size * 0.4).round}px;",
        aria: { hidden: true }
    end
  end
end
