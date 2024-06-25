# frozen_string_literal: true

module Jobs
  module WeeklyNewsletter
    class SendNewsletter < ::Jobs::Scheduled
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
        # exclude posts that are not visible for a regular user
        posts = Post.where("created_at >= ?", 1.week.ago).where("visible = true").where("post_type = 1").order(created_at: :desc).limit(10)

        # check if there are any posts
        if posts.empty? || posts.nil?
          Rails.logger.info "Not sending newsletter: No recently created posts found for newsletter"
          return
        end

        # send the newsletter to all users who want to receive it
        User
          .where("id > 0")
          .find_each do |user|
            next if not user.custom_fields[:receive_newsletter]

            begin
              ::WeeklyNewsletter::NewsletterMailer.newsletter(user, posts).deliver_now
            rescue => e
              Rails.logger.error "Error sending weekly newsletter: #{e.message}"
            end
          end

        Rails.logger.info "Weekly Newsletter job complete."
      end
    end
  end
end
