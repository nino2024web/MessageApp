class RemoveCountryFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :country, :string
  end
end
