# RouteInterceptor [![Gem Version](https://badge.fury.io/rb/route_interceptor.svg)](https://badge.fury.io/rb/route_interceptor)

![CI](https://github.com/ChapterHouse/route_interceptor/actions/workflows/ci.yml/badge.svg)

Ruby gem providing the ability to intercept existing `ActionDispatch::Journey::Route`s and direct to another
known path or controller and method (aka cam).

## Configuration
Configurations for source to destination intercepting is supported for the following scenarios:

|  Source route<br/> exists?  | Source <br/>specified as | Destination<sup>1</sup> |   Supported?   |
|:---------------------------:|:------------------------:|:-----------------------:|:--------------:|
|             yes             |     path<sup>3</sup>     |          path           |      yes       |
|             yes             |           path           |           cam           |      yes       |
|             yes             |      cam<sup>4</sup>     |          path           |      yes       |
|             yes             |           cam            |           cam           |      yes       |
|             no              |           path           |          path           |      yes       |
|             no              |           path           |           cam           |      yes       |
|             no              |           cam            |        path/cam         | no<sup>2</sup> |

<sup>1</sup>The destination route must exist. Apparently HR says routing to /dev/null is a violation of something or other.... blah blah blah.

<sup>2</sup>The source can be specified as a cam only if the path can be determined by looking at the existing routes. If it isn't there we don't
know where to route from. Tried /dev/random. Received HR visit #2.

<sup>3</sup> path - standard routes path, ie: /cars

<sup>4</sup> cam - Controller and Method. ie: cars#index

### Structure of Configuration
The following is a yaml interpretation of the configuration but its function is to demonstrate what the object loaded by
either the file or proc should represent to the interceptor. The equivalent can also be done via json as a personal preference.

```yaml
routes:
- source:
  destination:
  via: []
  add_params: {}
  name:
```

| column      | description                                                                                                                                                                                                                                     |
|-------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| source      | The `source` can be one of the following options:<br/><li>path, example(s): `/notifications`</li><li>cam, example(s): `notifications#index`</li>                                                                                                |
| destination | The `destination` must be a **<u>known</u>** endpoint with one of the following options:<br/><li>path, example(s): `/notifications`</li><li>cam, example(s): `notifications#index`</li>                                                         |
| via         | The `via` is the [http verb][http_verbs] utilized in the creation of the [match method][http_verb_constraints] construction. As noted within the documentation, this may be an array of values including the option of `:all`                   |
| add_params  | The `add_params` provides the ability inject new parameters into the incoming request.                                                                                                                                                          |
| name        | The `name` is an optional value that can be used to identifiy a route interception. This value must be given if the source, destination, or via are to be updated at runtime without rebooting. `add_params` can always be dynamically updated. |


### Load Configuration
Configurations supported for determining the intercepting combinations are retrieved in one of the following methods:
* File
* Initializer
* Url*

**Url is a forth coming enhancement that will allow a retrieval from a configured url endpoint. For now this can be accomplished manually via a proc.*

#### File Configuration
The file configuration in the interceptor utilizes the [app_config_for][app_config_for] library to load
a `route_interceptor.yml` file from the `/config` folder of the consuming rails application.

By default, the sequence in the loading of the interception configurations utilizes the file configuration mode. Updates
to the yaml file on the file system will trigger an update to the intercept configuration for your application.


#### Rails initializer
If you want to change from the file to proc based data retrieval, you may simply configure the interceptor to load from a proc.
You perform this by adding a `route_interceptor.rb` initializer within your `/config/initializers` with the following
configuration:
```ruby
RouteInterceptor.configure do |config|
  config.route_source = proc {
    { routes: [] }
  }
end
```
Now the frequency of checking for updates in this configuration will be on a scheduled interval of every 15 minutes
on the quarter hour. You may also force the check regardless of the source type to be scheduled by simply adding it
to the configuration as follows:
```ruby
RouteInterceptor.configure do |config|
  config.update_schedule = :scheduled
  config.route_source = proc {
    { routes: [] } # Could also do a http retrieval here if desired.
  }
end
```

Schedule at a semi regular update interval by returning the time of the next scheduled update.
```ruby
RouteInterceptor.configure do |config|
  config.update_schedule = :scheduled
  # Update every five minutes, but take a one hour lunch break.
  config.next_scheduled_update = proc { Time.hour == 12 ? 1.hour.from_now : 5.minutes.from now }
  config.route_source = proc {
    { routes: [] } # Could also do a http retrieval here if desired.
  }
end
```


Change to a more highly controlled determination of when to look for new changes. Return true or false if things have changed and need to be reread.
```ruby
RouteInterceptor.configure do |config|
  config.update_schedule = :polling
  # With the polling option we will signify an update during every other second unless it is 7am. 7am updates all the time. What a try hard.
  # Just return true or false to signify that things have changed and should be reread.
  config.source_changed = proc { |last_updated| Time.now.second.odd? || last_updated.hour == 7}
  config.route_source = proc {
    { routes: [] } # Could also do a http retrieval here if desired.
  }
end
```






## Development
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Releasing
To release a new version, update the version number in the `version.rb`. Then, by selecting to create a
[new release](https://github.com/ChapterHouse/route_interceptor/releases/new) and `Publish release`,
the [Continuous Delivery](https://github.com/ChapterHouse/route_interceptor/actions/workflows/cd.yml)
GitHub Action will build and then release the artifact to [rubygems.org](https://rubygems.org).

## Contributing
See [Contribution Guide](https://github.com/ChapterHouse/route_interceptor/wiki/Contribution-Guide)

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct
Everyone interacting in the RouteInterceptor project's codebases, issue trackers, chat rooms and mailing lists is expected to
follow the [code of conduct][9].

[1]: https://github.com/ChapterHouse/route_interceptor/issues
[2]: http://gun.io/blog/how-to-github-fork-branch-and-pull-request
[3]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[4]: ./CHANGELOG.md
[5]: ./MIT-LICENSE
[6]: http://gitready.com/advanced/2009/02/10/squashing-commits-with-rebase.html
[7]: https://help.github.com/articles/using-pull-requests
[8]: ./CONTRIBUTORS.md
[9]: ./CODE_OF_CONDUCT.md
[http_verbs]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods
[http_verb_constraints]: https://guides.rubyonrails.org/routing.html#http-verb-constraints
[app_config_for]: https://github.com/ChapterHouse/app_config_for
