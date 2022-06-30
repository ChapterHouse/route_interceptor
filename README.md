# RouteInterceptor [![Gem Version](https://badge.fury.io/rb/route_interceptor.svg)](https://badge.fury.io/rb/route_interceptor)

![CI](https://github.com/ChapterHouse/route_interceptor/actions/workflows/ci.yml/badge.svg)

Ruby gem providing the ability to intercept existing `ActionDispatch::Journey::Route`s and direct to another
known path or controller and method (aka cam).

## Configuration
Configurations for source to destination intercepting is supported for the following scenarios:

| Source       | Destination | Supported? |
|--------------|-------------|------------|
| path exists  | path exists | yes        |
| path missing | path exists | yes        |
| path exists  | cam exists  | yes        |
| path missing | cam exists  | yes        |
| cam exists   | path exists | yes        |
| cam exists   | cam exists  | yes        |
| cam missing  | n/a         | no         |

*Controller and method (cam) has an implicit requirement that the searching for an existing route has to be able to
identify the controller and method*

### Structure of Configuration
The following is a yaml interpretation of the configuration but its function is to demonstrate what the object loaded by
either the file or proc should represent to the interceptor.

```yaml
routes:
- source:
  destination:
  via: []
  param_mapping: {}
  name:
```

| column        | description                                                                                                                                                                                                                   |
|---------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| source        | The `source` can be one of the following options:<br/><li>path, example(s): `/notifications`</li><li>cam, example(s): `notifications#index`</li>                                                                              |
| destination   | The `destination` must be a **<u>known</u>** endpoint with one of the following options:<br/><li>path, example(s): `/notifications`</li><li>cam, example(s): `notifications#index`</li>                                       |
| via           | The `via` is the [http verb][http_verbs] utilized in the creation of the [match method][http_verb_constraints] construction. As noted within the documentation, this may be an array of values including the option of `:all` |
| param_mapping | The `param_mapping` provides the ability to both map existing incoming parameters to new parameters as well as inject new ones.                                                                                               |
| name          | The `name` is something...                                                                                                                                                                                                    |


### Load Configuration
Configurations supported for determining the intercepting combinations are retrieved in one of the following methods
* File
* Proc

By default, the sequence in the loading of the interception configurations utilizes the file configuration option.  Updates
to the yaml file on the file system will trigger an update to the intercept configuration for your application.

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
    { routes: [] }
  }
end
```

#### File Configuration
The file configuration in the interceptor utilizes the [app_config_for][app_config_for] library to load
a `route_interceptor.yml` file from the `/config` folder of the consuming rails application.  

#### Proc Configuration


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
Help us to make this project better by contributing. Whether it's new features, bug fixes, or simply improving documentation,
your contributions are welcome. Please start with logging a [github issue][1] or submit a pull request.

Before you contribute, please review these guidelines to help ensure a smooth process for everyone.

Thanks!!

### Issue Reporting

* Please browse our [existing issues][1] before logging new issues.
* Check that the issue has not already been fixed in the `master` branch.
* Open an issue with a descriptive title and a summary.
* Please be as clear and explicit as you can in your description of the problem.
* Please state the version of {technical dependencies} and `route_inspector` you are using in the description.
* Include any relevant code in the issue summary.

### Pull Requests

* Read [how to properly contribute to open source projects on Github][2].
* Fork the project.
* Use a feature branch.
* Write [good commit messages][3].
* Use the same coding conventions as the rest of the project.
* Commit locally and push to your fork until you are happy with your contribution.
* Make sure to add tests and verify all the tests are passing when merging upstream.
* Add an entry to the [Changelog][4] accordingly.
* Please add your name to the [CONTRIBUTORS.md][8] file. Adding your name to the [CONTRIBUTORS.md][8] file signifies agreement to all rights and reservations provided by the [License][5].
* [Squash related commits together][6].
* Open a [pull request][7].
* The pull request will be reviewed by the community and merged by the project committers.

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