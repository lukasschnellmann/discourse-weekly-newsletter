module ::WeeklyNewsletter
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace WeeklyNewsletter
  end
end
