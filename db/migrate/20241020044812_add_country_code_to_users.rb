class AddCountryCodeToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :country_code, :string, null: false, default: ''
  end
end
