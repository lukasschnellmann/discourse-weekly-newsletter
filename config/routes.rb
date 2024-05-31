# frozen_string_literal: true

WeeklyNewsletter::Engine.routes.draw do
  # define routes here
end

Discourse::Application.routes.draw { mount ::WeeklyNewsletter::Engine, at: "weekly_newsletter" }
