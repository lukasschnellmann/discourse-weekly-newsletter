# frozen_string_literal: true

# name: discourse-weekly-newsletter
# about: A plugin to send weekly newsletters on a specific time and day of the week
# version: 1.1.0
# authors: Lukas Schnellmann
# url: https://github.com/lukasschnellmann/discourse-weekly-newsletter
# required_version: 2.7.0

enabled_site_setting :weekly_newsletter_enabled

module ::WeeklyNewsletter
  PLUGIN_NAME = "weekly-newsletter"
end

require_relative "lib/weekly_newsletter/engine"

DiscoursePluginRegistry.serialized_current_user_fields << "receive_newsletter"

after_initialize do
  User.register_custom_field_type "receive_newsletter", :boolean
  register_editable_user_custom_field :receive_newsletter
  
  on :user_created do |user|
    user.custom_fields["receive_newsletter"] = true
    user.save!
  end

  require_relative "app/jobs/weekly_newsletter/send_newsletter"
end
