class AddIsDeptToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :is_dept, :boolean
  end
end
