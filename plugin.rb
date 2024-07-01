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

after_initialize do
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
        posts = Post.where("created_at >= ?", 1.week.ago)
        Rails.logger.info "Found #{posts.count} posts created in the last week!"

        if posts.count == 0
          Rails.logger.info "No posts found in the last week, not sending newsletter!"
          return
        end

        User.where("id > 0").find_each do |user|
          next if not user.custom_fields[:receive_newsletter]

          begin
            ::WeeklyNewsletter::NewsletterMailer.newsletter(user, posts).deliver_now
          rescue => e
            Rails.logger.error "Error sending weekly newsletter: #{e.message}"
          end
        end

        Rails.logger.info "Weekly Newsletter job done!"
      end
    end
  end  
end
