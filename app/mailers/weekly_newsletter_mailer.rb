# frozen_string_literal: true

class WeeklyNewsletterMailer < ActionMailer::Base
  default from: SiteSetting.notification_email

  def send_email(user, posts)
    @user = user
    @posts = posts
    @base_url = Discourse.base_url
    @current_host = Discourse.current_hostname

    mail(to: @user.email, subject: "GEOWebforum: Beiträge der letzten Woche") do |format|
      format.html { render "newsletter" }
    end
  end
end
