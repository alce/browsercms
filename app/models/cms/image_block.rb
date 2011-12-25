module Cms
  class ImageBlock < Cms::AbstractFileBlock

    acts_as_content_block :versioned => {:version_foreign_key => :file_block_id},
                          :has_attachments => true, :taggable => true

    has_attachment :image, :url => ":attachment_file_path", :styles => {:thumb => "80x80"}

    validates_attachment_presence :image, :message => "You must upload a file"

    # def set_attachment_file_path
    #   if @attachment_file_path && @attachment_file_path != attachment.file_path
    #     attachment.file_path = @attachment_file_path
    #   end
    # end

    # def set_attachment_section
    #   if @attachment_section_id && @attachment_section_id != attachment.section_id
    #     attachment.section_id = @attachment_section_id
    #   end
    # end

    def self.display_name
      "Image"
    end

  end
end
