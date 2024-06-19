# frozen_string_literal: true

# name: discourse-weekly-newsletter
# about: A plugin to send weekly newsletters on a specific time and day of the week
# version: 1.1.0
# authors: Lukas Schnellmann
# url: https://github.com/lukasschnellmann/discourse-weekly-newsletter
# required_version: 2.7.0

enabled_site_setting :weekly_newsletter_enabled

module ::WeeklyNewsletter
  PLUGIN_NAME = "weekly_newsletter"
end

DiscoursePluginRegistry.serialized_current_user_fields << 'receive_newsletter'

after_initialize do
  User.register_custom_field_type 'receive_newsletter', :boolean
  register_editable_user_custom_field :receive_newsletter

  User.where("id > 0").find_each do |user|
    user.custom_fields['receive_newsletter'] = true if user.custom_fields['receive_newsletter'].nil?
    user.save!
  end

  module ::Jobs
    class WeeklyNewsletter < ::Jobs::Scheduled
      daily at: 3.hours

      def execute(args)
        return unless SiteSetting.weekly_newsletter_enabled

        # initialize logger
        Rails.logger = Logger.new(STDOUT)
        Rails.logger.info "Weekly Newsletter job running..."

        current_day = Time.zone.now.strftime("%A").downcase
        newsletter_day = SiteSetting.weekly_newsletter_day.downcase
        if current_day != newsletter_day
          Rails.logger.info(
            "Not sending newsletter: Today is #{current_day}, but the newsletter is scheduled for #{newsletter_day}",
          )
          return
        end

        # get all posts created in the last week
        posts = Post.where("posts.created_at >= ?", 1.week.ago).limit(10)

        # check if there are any posts
        if posts.empty?
          Rails.logger.info(
            "Not sending newsletter: No recently created posts found for newsletter",
          )
          return
        end

        # send the newsletter to all users who want to receive it
        User
          .where("id > 0")
          .find_each do |user|
            next if not user.custom_fields[:receive_newsletter]

            begin
              WeeklyNewsletterMailer.newsletter(user, posts).deliver_now
            rescue => e
              Rails.logger.error "Error sending weekly newsletter: #{e.message}"
            end
          end

        Rails.logger.info "Weekly Newsletter job complete."
      end
    end
  end
end
