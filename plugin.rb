# frozen_string_literal: true

# name: weekly-newsletter
# about: A plugin to send weekly newsletters on a specific time and day of the week
# meta_topic_id: N/A
# version: 0.1
# authors: Lukas Schnellmann
# url: N/A
# required_version: 2.7.0

enabled_site_setting :weekly_newsletter_enabled

module ::WeeklyNewsletter
  PLUGIN_NAME = "weekly_newsletter"
end

require_relative "lib/weekly_newsletter/engine"

DiscoursePluginRegistry.serialized_current_user_fields << 'receive_newsletter'

after_initialize do
  User.register_custom_field_type 'receive_newsletter', :boolean
  register_editable_user_custom_field :receive_newsletter

  module ::Jobs
    class WeeklyNewsletter < ::Jobs::Scheduled
      daily at: 3.hours

      def execute(args)
        current_day = Time.zone.now.strftime("%A").downcase
        newsletter_day = SiteSetting.weekly_newsletter_day.downcase
        return if current_day != newsletter_day

        # initialize logger
        Rails.logger = Logger.new(STDOUT)
        Rails.logger.info "Weekly Newsletter job running..."

        # get all posts created in the last week
        posts = Post.where("posts.created_at >= ?", 1.week.ago)

        # check if there are any posts
        if posts.empty?
          Rails.logger.info(
            "Not sending newsletter: No recently created posts found for newsletter"
          )
          return
        end

        # send the newsletter to all users who want to receive it
        User.where('id > 0').find_each do |user|
          next if not user.custom_fields[:receive_newsletter]

          begin
            WeeklyNewsletterMailer.newsletter(user, posts).deliver_now
          rescue => e
            Rails.logger.error "Error sending weekly newsletter: #{e.message}"
          end
        end
      end
    end
  end
end
