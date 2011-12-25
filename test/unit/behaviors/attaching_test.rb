require 'test_helper'


ActiveRecord::Base.connection.instance_eval do
  drop_table(:default_attachables) rescue nil
  drop_table(:default_attachable_versions) rescue nil
  create_content_table(:default_attachables, :prefix=>false) do |t|
    t.string :name
    t.timestamps
  end

  drop_table(:versioned_attachables) rescue nil
  drop_table(:versioned_attachable_versions) rescue nil
  create_content_table(:versioned_attachables, :prefix=>false) do |t|
    t.string :name
    t.timestamps
  end
end

class DefaultAttachable < ActiveRecord::Base
  acts_as_content_block :has_attachments => true
  has_attachment :spreadsheet
end

class VersionedAttachable < ActiveRecord::Base
  acts_as_content_block :has_attachments => true
  has_attachment :cover

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
end


class AttachableBehaviorTest < ActiveSupport::TestCase

  def setup
    @file = mock_file
    @attachable = DefaultAttachable.create!(:name => "File Name",
                                            :attachments_attributes => {
                                              "0" => {
                                                :data => @file,
                                                :section_id => root_section,
                                                :attachment_name => "spreadsheet"}},
                                            :publish_on_save => true)
  end

  test "Saving a block which an attachment should save both and associate it" do
    content = DefaultAttachable.find(@attachable.id)
    assert_not_nil content.attachment
  end
end


class DefaultAttachableTest < ActiveSupport::TestCase
  def setup
    #file is a mock of the object that Rails wraps file uploads in
    @file = mock_file

    @section = root_section
  end

  test "Create a block with an attached file" do
    @attachable = DefaultAttachable.create!(:name => "File Name", :attachment_file => @file, :publish_on_save => true)

    assert_equal @section, @attachable.attachment_section

    @attachable = DefaultAttachable.find(@attachable.id)

    assert_not_nil @attachable.attachment, "Should have an attachment"
    assert_equal @section, @attachable.attachment_section

  end

  def test_create_with_attachment_file
    @attachable = DefaultAttachable.new(:name => "File Name",
                                        :attachment_file => @file, :publish_on_save => true)

    attachable_count = DefaultAttachable.count

    assert_valid @attachable
    @attachable.save!

    assert_incremented attachable_count, DefaultAttachable.count
    assert_equal @section, @attachable.attachment_section
    assert_equal @section.id, @attachable.attachment_section_id
    assert_equal "/attachments/foo.jpg", @attachable.attachment_file_path

    reset(:attachable)

    assert_equal @section, @attachable.attachment_section
    assert_equal @section.id, @attachable.attachment_section_id
    assert_equal "/attachments/foo.jpg", @attachable.attachment_file_path
    assert @attachable.attachment.published?
  end

  def test_create_without_attachment_and_then_add_attachment_on_edit
    @attachable = DefaultAttachable.new(:name => "File Name",
                                        :attachment_file => nil, :publish_on_save => true)

    assert_difference 'DefaultAttachable.count' do
      assert_valid @attachable
      @attachable.save!
    end

    assert_nil @attachable.attachment_file_path
    assert_nil @attachable.attachment, "There should be no attachment saved."

    reset(:attachable)

    @attachable.attachment_file = @file
    assert_equal true, @attachable.save!
    assert_equal true, @attachable.publish!

    assert_equal "/attachments/foo.jpg", @attachable.attachment_file_path

    assert_not_nil @attachable.attachment, "After attaching a file, the Attachment should exist"

    reset(:attachable)

    assert_not_nil @attachable.attachment, "The attachment should have been saved and reloaded."
    assert_equal @section, @attachable.attachment_section
    assert_equal @section.id, @attachable.attachment_section_id
    assert_equal "/attachments/foo.jpg", @attachable.attachment_file_path
    assert @attachable.attachment.published?
  end


end

class AttachingTest < ActiveSupport::TestCase

  def test_block_without_attaching_behavior
    assert !Cms::HtmlBlock.belongs_to_attachment?
  end

  def test_file_path_sanitization
    {
        "Draft #1.txt" => "Draft_1.txt",
        "Copy of 100% of Paul's Time(1).txt" => "Copy_of_100_of_Pauls_Time-1-.txt"
    }.each do |example, expected|
      assert_equal expected,
                   VersionedAttachable.new.sanitize_file_path(example)
    end
  end

end

class AttachableTest < ActiveSupport::TestCase

  def setup
    #file is a mock of the object that Rails wraps file uploads in
    @file = mock_file(:original_filename => "sample_upload.txt")

    @section = Factory(:section, :name => "attachables", :parent => root_section)
  end

  def test_create_with_attachment_section_id_attachment_file_and_attachment_file_path
    @attachable = VersionedAttachable.new(:name => "Section ID, File and File Name",
                                          :attachment_section_id => @section.id,
                                          :attachment_file => @file,
                                          :attachment_file_path => "test.jpg")

    assert_was_saved_properly
  end

  def test_create_with_attachment_section_attachment_file_and_attachment_file_path
    @attachable = VersionedAttachable.new(:name => "Section, File and File Name",
                                          :attachment_section => @section,
                                          :attachment_file => @file,
                                          :attachment_file_path => "test.jpg")

    assert_was_saved_properly
  end

  def test_create_with_an_attachment_section_but_no_attachment_file
    @attachable = VersionedAttachable.new(:name => "Section, No File",
                                          :attachment_section => @section)

    attachable_count = VersionedAttachable.count

    assert !@attachable.save

    assert_equal attachable_count, VersionedAttachable.count
    assert_equal @section, @attachable.attachment_section
    assert_equal @section.id, @attachable.attachment_section_id
    assert_nil @attachable.attachment_file_path
  end

  def test_create_with_an_attachment_file_but_no_attachment_section
    @attachable = VersionedAttachable.new(:name => "File Name, No File",
                                          :attachment_file_path => "whatever.jpg")

    attachable_count = VersionedAttachable.count

    assert !@attachable.save

    assert_equal attachable_count, VersionedAttachable.count
    assert_nil @attachable.attachment_section
    assert_nil @attachable.attachment_section_id
    assert_equal "whatever.jpg", @attachable.attachment_file_path
  end

  def test_create_screwy_attachment_file_name
    @attachable = VersionedAttachable.new(:name => "Section ID, File and File Name",
                                          :attachment_section_id => @section.id,
                                          :attachment_file => @file,
                                          :attachment_file_path => "Broken? Yes & No!.txt")

    attachable_count = VersionedAttachable.count

    assert @attachable.save

    assert_incremented attachable_count, VersionedAttachable.count
    assert_equal "/Broken_Yes_-_No.txt", @attachable.attachment_file_path
  end

  def test_updating_the_attachment_file_name
    @attachable = VersionedAttachable.create!(:name => "Foo",
                                              :attachment_section_id => @section.id,
                                              :attachment_file => @file,
                                              :attachment_file_path => "test.jpg")
    reset(:attachable)

    attachment_count = Cms::Attachment.count
    attachment_version = @attachable.attachment_version
    attachment_version_count = Cms::Attachment::Version.count

    assert @attachable.update_attributes(:attachment_file_path => "test2.jpg", :publish_on_save => true)

    assert_equal attachment_count, Cms::Attachment.count

    assert_incremented attachment_version, @attachable.attachment_version
    assert_incremented attachment_version_count, Cms::Attachment::Version.count
    assert_equal "/test2.jpg", @attachable.attachment_file_path

    reset(:attachable)

    assert_equal attachment_count, Cms::Attachment.count
    assert_incremented attachment_version, @attachable.attachment_version
    assert_incremented attachment_version_count, Cms::Attachment::Version.count
    assert_equal "/test2.jpg", @attachable.attachment_file_path
  end

  def test_updating_the_attachment_file
    @attachable = VersionedAttachable.create!(:name => "Foo",
                                              :attachment_section_id => @section.id,
                                              :attachment_file => @file,
                                              :attachment_file_path => "test.jpg")

    reset(:attachable)

    @file2 = mock_file(:original_filename => "second_upload.txt")

    attachment_count = Cms::Attachment.count
    attachment_version = @attachable.attachment_version
    attachment_version_count = Cms::Attachment::Version.count

    assert @attachable.update_attributes(:attachment_file => @file2)

    assert_equal attachment_count, Cms::Attachment.count
    assert_equal attachment_version, @attachable.reload.attachment_version
    assert_incremented attachment_version_count, Cms::Attachment::Version.count
    @file.rewind
    assert_equal @file.read, open(@attachable.attachment.full_file_location) { |f| f.read }

    reset(:attachable)
    @file.rewind
    @file2.rewind

    assert_equal @file.read, open(@attachable.attachment.as_of_version(1).full_file_location) { |f| f.read }
    assert_equal @file2.read, open(@attachable.attachment.as_of_version(2).full_file_location) { |f| f.read }

  end

  protected
  def assert_was_saved_properly
    attachable_count = VersionedAttachable.count

    assert @attachable.save

    assert_incremented attachable_count, VersionedAttachable.count
    assert_equal @section, @attachable.attachment_section
    assert_equal @section.id, @attachable.attachment_section_id
    assert_equal "/test.jpg", @attachable.attachment_file_path

    reset(:attachable)

    assert_equal @section, @attachable.attachment_section
    assert_equal @section.id, @attachable.attachment_section_id
    assert_equal "/test.jpg", @attachable.attachment_file_path
  end

end

class VersionedAttachableTest < ActiveSupport::TestCase
  def setup
    #file is a mock of the object that Rails wraps file uploads in
    @file = mock_file

    @section = Factory(:section, :name => "attachables", :parent => root_section)

    @attachable = VersionedAttachable.create!(:name => "Foo v1",
                                              :attachment_section_id => @section.id,
                                              :attachment_file => @file,
                                              :attachment_file_path => "test.jpg")
    reset(:attachable)
  end

  def test_updating_the_versioned_attachable
    attachment_count = Cms::Attachment.count
    attachment_version = @attachable.attachment_version
    attachment_version_count = Cms::Attachment::Version.count

    assert @attachable.update_attributes(:name => "Foo v2")

    assert_equal attachment_count, Cms::Attachment.count
    assert_equal attachment_version, @attachable.attachment_version
    assert_equal attachment_version_count, Cms::Attachment::Version.count
    assert_equal "Foo v2", @attachable.name
    assert_equal @attachable.as_of_version(1).attachment, @attachable.as_of_version(2).attachment
  end

  def test_updating_the_versioned_attachable_attachment_file_path
    attachable_count = VersionedAttachable.count
    attachment_count = Cms::Attachment.count
    attachment_version = @attachable.attachment_version
    attachment_version_count = Cms::Attachment::Version.count

    assert @attachable.update_attributes(:attachment_file_path => "test2.jpg")

    assert_equal attachable_count, VersionedAttachable.count
    assert_equal attachment_count, Cms::Attachment.count
    assert_incremented attachment_version, @attachable.attachment_version
    assert_incremented attachment_version_count, Cms::Attachment::Version.count
    assert_equal "/test2.jpg", @attachable.attachment_file_path

    assert_equal @attachable.as_of_version(1).attachment, @attachable.as_of_version(2).attachment
    assert_not_equal @attachable.as_of_version(1).attachment_version, @attachable.as_of_version(2).attachment_version
    assert_equal "/test.jpg", @attachable.as_of_version(1).attachment_file_path
    assert_equal "/test2.jpg", @attachable.as_of_version(2).attachment_file_path
  end

  def test_updating_the_versioned_attachable_attachment_file
    @file2 = mock_file(:original_filename => "second_upload.txt")

    attachable_count = VersionedAttachable.count
    attachment_count = Cms::Attachment.count
    attachment_version = @attachable.attachment_version
    attachment_version_count = Cms::Attachment::Version.count

    assert @attachable.update_attributes(:attachment_file => @file2)

    assert_equal attachable_count, VersionedAttachable.count
    assert_equal attachment_count, Cms::Attachment.count
    assert_incremented attachment_version, @attachable.attachment_version
    assert_incremented attachment_version_count, Cms::Attachment::Version.count

    @file2.rewind
    assert_equal @file2.read, open(@attachable.attachment.full_file_location) { |f| f.read }

    @file.rewind
    assert_equal @file.read, open(@attachable.attachment.as_of_version(1).full_file_location) { |f| f.read }

    @file2.rewind
    assert_equal @file2.read, open(@attachable.attachment.as_of_version(2).full_file_location) { |f| f.read }
  end

end

