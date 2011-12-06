module Cms
  class FileBlock < Cms::AbstractFileBlock

    acts_as_content_block :has_attachments => true, :taggable => true
    has_attachment :file, :url => ":attachment_file_path"
    validates_attachment_presence :file, :message => "You must upload a file"

    def set_attachment_file_path
      if @attachment_file_path && @attachment_file_path != attachment.file_path
        attachment.file_path = @attachment_file_path
      end
    end

    def set_attachment_section
      if @attachment_section_id && @attachment_section_id != attachment.section_id
        attachment.section_id = @attachment_section_id
      end
    end

    def self.display_name
      "File"
    end

  end
end
