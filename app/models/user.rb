class User < ApplicationRecord
  # === Mixins ===

  # === Constants ===

  # === Gem macros ===
  has_paper_trail
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, #:trackable,
         authentication_keys: [:login]

  # === Attributes ===
  attr_writer :login

  # === Associations ===
  has_one_attached :avatar

  # === Scopes ===

  # === Validations ===
  # only allow letter, number, underscore and punctuation.
  validates :name,
             presence: true,
             length: { maximum: 50 },
             uniqueness: { case_sensitive: false },
             format: { with: /^[a-zA-Z0-9_\.\-]*$/, :multiline => true }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                   format: { with: VALID_EMAIL_REGEX },
                   uniqueness: true

  validates :time_zone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }
  validates :preferred_locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, allow_blank: true
  validates :job_title, length: { maximum: 100 }, allow_blank: true

  # === Callbacks ===

  # === Class methods ===
  # === Class methods - Queries ===
  # Provide SQL for ordering users in the navigator (show page prev/next)
  def self.navigator_order_sql
    "users.name ASC"
  end

  # from devise wiki for allowing alternate login keys (name or email)
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(["name = :value OR lower(email) = lower(:value)",
        { :value => login }]).first
    elsif conditions.has_key?(:name) || conditions.has_key?(:email)
      where(conditions.to_h).first
    end
  end

  # === Public methods ===
  # from devise wiki for allowing alternate login keys (name or email)
  def login
    @login || self.name || self.email
  end

  def label
    name
  end

  # Fallback avatar content when no image has been attached - initials from
  # the name, same idea as the gravatar it replaces but with no dependency on
  # a third party image fetch succeeding. The name format here doesn't allow
  # spaces (see validation above), so this is the name's first two
  # characters, not "first letter of each word".
  def initials
    name.to_s[0, 2].upcase
  end

  private

    # === Private methods ===
    def self.ransackable_attributes(auth_object = nil)
      ["name", "email", "job_title", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      []
    end

end
