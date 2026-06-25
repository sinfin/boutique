# frozen_string_literal: true

class AddFolio7UserColumnsToDummySchema < ActiveRecord::Migration[8.0]
  def change
    add_column :folio_users, :superadmin, :boolean, default: false, null: false unless column_exists?(:folio_users, :superadmin)
    add_column :folio_users, :console_url, :string unless column_exists?(:folio_users, :console_url)
    add_column :folio_users, :console_url_updated_at, :datetime unless column_exists?(:folio_users, :console_url_updated_at)
    add_column :folio_users, :degree_pre, :string, limit: 32 unless column_exists?(:folio_users, :degree_pre)
    add_column :folio_users, :degree_post, :string, limit: 32 unless column_exists?(:folio_users, :degree_post)
    add_column :folio_users, :phone_secondary, :string unless column_exists?(:folio_users, :phone_secondary)
    add_column :folio_users, :born_at, :date unless column_exists?(:folio_users, :born_at)
    add_column :folio_users, :bank_account_number, :string unless column_exists?(:folio_users, :bank_account_number)
    add_column :folio_users, :company_name, :string unless column_exists?(:folio_users, :company_name)
    add_column :folio_users, :time_zone, :string, default: "Prague" unless column_exists?(:folio_users, :time_zone)
    add_column :folio_users, :preferred_locale, :string unless column_exists?(:folio_users, :preferred_locale)
    add_column :folio_users, :console_preferences, :jsonb unless column_exists?(:folio_users, :console_preferences)
    add_column :folio_users, :failed_attempts, :integer, default: 0, null: false unless column_exists?(:folio_users, :failed_attempts)
    add_column :folio_users, :unlock_token, :string unless column_exists?(:folio_users, :unlock_token)
    add_column :folio_users, :locked_at, :datetime unless column_exists?(:folio_users, :locked_at)

    unless column_exists?(:folio_users, :auth_site_id)
      add_reference :folio_users, :auth_site, null: true, foreign_key: { to_table: :folio_sites }
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE folio_users
             SET auth_site_id = (SELECT id FROM folio_sites ORDER BY id ASC LIMIT 1)
           WHERE auth_site_id IS NULL
        SQL
      end
    end

    if column_exists?(:folio_users, :auth_site_id)
      change_column_null :folio_users, :auth_site_id, false
    end
  end
end
