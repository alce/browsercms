#TODO: this should be configured through Cms::Attachments module
Cms.attachment_file_permission = 0640

# Core project needs this namespace. (Though now that fixtures are gone, this might need to be rechecked.)
Cms.table_prefix = "cms_"

Cms::Attachments.configure
