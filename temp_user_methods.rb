# Associations
  has_many :has_roles, dependent: :destroy, class_name: "HasRole"
  has_many :roles, through: :has_roles, class_name: "Role"
  
  # Callbacks
  after_create :assign_default_roles
  
  # Role-based methods
  def has_role?(role_name)
    roles.exists?(role_name: role_name)
  end
  
  def add_role(role_name)
    role = Role.find_by(role_name: role_name)
    return false unless role
    
    has_roles.find_or_create_by!(
      parent: email,
      parenttype: "User",
      role: role_name,
      user: self
    )
  end
  
  def instructor?
    has_role?("Course Creator")
  end
  
  def assign_default_roles
    add_role("Student")
  end
