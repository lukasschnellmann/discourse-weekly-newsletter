# frozen_string_literal: true

class ::WeeklyNewsletterMailer < ActionMailer::Base
  default from: "info@geowebforum.ch"

  def newsletter(user, posts)
    @user = user
    @posts = posts
    @base_url = Discourse.base_url
    @current_host = Discourse.current_hostname
    
    img = File.open(
      "/home/lukas/geowebforum/plugins/weekly-newsletter/app/mailers/geowebforum_logo.svg"
    )
    img_base64 = Base64.strict_encode64(img.read)
    @logo_data_url = "data:image/svg+xml;base64,#{img_base64}"

    mail(to: @user.email, subject: "GEOWebforum: Beiträge der letzten Woche") do |format|
      format.html { render 'newsletter' }
    end

    File.open("/home/lukas/geowebforum/html.html", "w") { |f| f.write(render('newsletter')) }
  end
end