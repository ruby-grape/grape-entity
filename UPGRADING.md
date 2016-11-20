Upgrading Grape Entity
===============

### Upgrading to >= 0.6.0

#### Changes in Grape::Entity#inspect

The `Grape::Entity#inspect` method will no longer serialize the entity presenter with its options and delegator, but the exposed entity itself, using `#serializable_hash`.

See [#250](https://github.com/ruby-grape/grape-entity/pull/250) for more information.

### Upgrading to >= 0.5.1

#### Changes in NestedExposures.delete_if

`Grape::Entity::Exposure::NestingExposure::NestedExposures.delete_if` always returns exposures, regardless of delete result (used to be `nil` in negative case).

See [#203](https://github.com/ruby-grape/grape-entity/pull/203) for more information.
