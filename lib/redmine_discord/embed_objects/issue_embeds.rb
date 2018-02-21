require_relative '../embed_objects/field_helper'
require_relative '../wraps/wrapped_issue'
require_relative '../wraps/wrapped_journal'

module RedmineDiscord
  class NewIssueEmbed
    def initialize(context)
      @wrapped_issue = WrappedIssue.new context[:issue]
    end

    def notified_users
    notified_users = @wrapped_issue.notified_users
    notified_discord_users = []
    if notified_users != nil
      custom_field = UserCustomField.find_by_name('Discord UserId')
      notified_users.each do |user|
        discord_id = begin
                       user.custom_field_value(custom_field)
                     rescue
                       []
                     end
        notified_discord_users.push("<@#{discord_id}>") if discord_id
      end
    end
    notified_discord_users.join(' ')
    end

    def to_embed_array
      # prepare fields in heading / remove nil fields
      fields = @wrapped_issue.to_creation_information_fields.compact

      description_field = @wrapped_issue.to_description_field

      if description_field != nil
        fields.push RedmineDiscord::get_separator_field unless fields.empty?
        fields.push description_field
      end

      heading_url = @wrapped_issue.resolve_absolute_url

      [{
           url: heading_url,
           title: "[New issue] #{@wrapped_issue.to_heading_title}",
           color: get_fields_color,
           fields: fields
       }]
    end

    private

    def get_fields_color
      65280
    end
  end

  class IssueEditEmbed
    def initialize(context)
      @wrapped_issue = WrappedIssue.new context[:issue]
      @wrapped_journal = WrappedJournal.new context[:journal]
    end

    def notified_users
      notified_users = @wrapped_issue.notified_users
      notified_discord_users = []
      if notified_users != nil
        custom_field = UserCustomField.find_by_name('Discord UserId')
        notified_users.each do |user|
          discord_id = begin
                         user.custom_field_value(custom_field)
                       rescue
                         []
                       end
          notified_discord_users.push("<@#{discord_id}>") if discord_id
        end
      end
      notified_discord_users.join(' ')
    end

    def to_embed_array
      fields = @wrapped_issue.to_diff_fields
      notes_field = @wrapped_journal.to_notes_field

      fields.push RedmineDiscord::get_separator_field unless fields.empty?

      fields.push @wrapped_journal.to_editor_field
      fields.push notes_field if notes_field

      heading_url = @wrapped_issue.resolve_absolute_url

      [{
           url: heading_url,
           title: "#{get_title_tag} #{@wrapped_issue.to_heading_title}",
           color: get_fields_color,
           fields: fields
       }]
    end

    def get_title_tag
      '[Issue update]'
    end

    def get_fields_color
      16752640
    end
  end

  class IssueCloseEmbed < IssueEditEmbed
    def get_title_tag
      '[Issue closed]'
    end

    def get_fields_color
      # a3a3a3 in hex
      10724259
    end
  end
end
