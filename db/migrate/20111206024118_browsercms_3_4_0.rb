class Browsercms340 < ActiveRecord::Migration
  def up
    add_content_column :cms_attachments, :data_file_name, :string
    add_content_column :cms_attachments, :data_content_type, :string
    add_content_column :cms_attachments, :data_file_size, :integer
    add_content_column :cms_attachments, :data_file_path, :string
    add_content_column :cms_attachments, :data_fingerprint, :string
    add_content_column :cms_attachments, :attachable_type, :string
    add_content_column :cms_attachments, :attachment_name, :string
    add_content_column :cms_attachments, :attachable_id, :integer
  end

  def down
    remove_content_column :cms_attachments, :data_file_name
    remove_content_column :cms_attachments, :data_content_type
    remove_content_column :cms_attachments, :data_file_size
    remove_content_column :cms_attachments, :data_file_path
    remove_content_column :cms_attachments, :data_fingerprint
    remove_content_column :cms_attachments, :attachable_type
    remove_content_column :cms_attachments, :attachment_name
    remove_content_column :cms_attachments, :attachable_id
  end
end
