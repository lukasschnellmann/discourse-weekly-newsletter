# **Weekly Newsletter** Plugin

## Plugin Summary

This Plugin sends a weekly newsletter to all users who have not disabled the newsletter in their preferences.

## Installing

* Add the plugin's repo url to your container's `app.yml` file

```yml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - mkdir -p plugins
          - git clone https://github.com/discourse/docker_manager.git
          - git clone https://github.com/Ebsy/discourse-nationalflags.git
```

* Rebuild the container

```
cd /var/discourse
git pull
./launcher rebuild app
```


See https://meta.discourse.org/t/install-a-plugin/19157/14