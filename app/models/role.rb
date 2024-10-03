class Role < ApplicationRecord
  has_and_belongs_to_many :users, :join_table => :users_roles

  belongs_to :resource,
             :polymorphic => true,
             :optional => true


  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true

  def self.ransackable_attributes(auth_object = nil)
    ["name", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user", "project", "tag"]
  end


  scopify
end
