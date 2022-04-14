# frozen_string_literal: true

class RmMimeTypeColumnFromFolioModels < ActiveRecord::Migration[7.0]
  def change
    remove_column :folio_files, :mime_type, :string
    remove_column :folio_private_attachments, :mime_type, :string
  end
end
