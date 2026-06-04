# Upgrading Grape Entity

### Upgrading to >= 1.1.0

`multi_json` gem is no longer a runtime dependency. Applications that relied on a configured `MultiJson` adapter should add it to their own `Gemfile`.

`expose :x, &:missing_method` no longer raises `ArgumentError` at definition time. Unknown methods now raise a native `NoMethodError` at call time.
If you rescue `ArgumentError` around entity rendering to catch typos in method names, update those rescue clauses to `NoMethodError`.

### Upgrading to >= 0.10.2

Official support for `FetchableObject` was removed.

See [#352](https://github.com/ruby-grape/grape-entity/pull/369) for more information.

### Upgrading to >= 0.8.2

Official support for ruby < 2.5 removed, ruby 2.5 only in testing mode, but no support.

In Ruby 3.0: the block handling will be changed
[language-changes point 3, Proc](https://github.com/ruby/ruby/blob/v3_0_0_preview1/NEWS.md#language-changes).
This:
```ruby
expose :that_method_without_args, &:method_without_args
```
will be deprecated.

Prefer to use this pattern for simple setting a value
```ruby
expose :method_without_args, as: :that_method_without_args
```

### Upgrading to >= 0.6.0

#### Changes in Grape::Entity#inspect

The `Grape::Entity#inspect` method will no longer serialize the entity presenter with its options and delegator, but the exposed entity itself, using `#serializable_hash`.

See [#250](https://github.com/ruby-grape/grape-entity/pull/250) for more information.

### Upgrading to >= 0.5.1

#### Changes in NestedExposures.delete_if

`Grape::Entity::Exposure::NestingExposure::NestedExposures.delete_if` always returns exposures, regardless of delete result (used to be `nil` in negative case).

See [#203](https://github.com/ruby-grape/grape-entity/pull/203) for more information.
