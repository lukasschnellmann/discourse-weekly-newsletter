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
  User.where("id > 0").find_each do |user|
    if user.custom_fields[:receive_newsletter].nil?
      user.custom_fields[:receive_newsletter] = true
      user.save!
    end
  end

  on :user_created do |user|
    user.custom_fields[:receive_newsletter] = true
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
  
        # check if today is the day the newsletter should be sent
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

        # do not send newsletter if no posts were found
        if posts.count == 0
          Rails.logger.info "No posts found in the last week, not sending newsletter!"
          return
        end

        was_sent = false

        # send newsletter to all users who have not opted out
        User.where("id > 0").find_each do |user|
          next if not user.custom_fields[:receive_newsletter]

          begin
            ::WeeklyNewsletter::NewsletterMailer.newsletter(user, posts).deliver_now
            was_sent = true
          rescue => e
            Rails.logger.error "Error sending weekly newsletter: #{e.message}"
          end
        end

        Rails.logger.info "Weekly Newsletter sent!" if was_sent
        Rails.logger.info "Weekly Newsletter job done!"
      end
    end
  end  
end
