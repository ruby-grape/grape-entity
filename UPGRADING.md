Upgrading Grape Entity
===============

### Upgrading to >= 0.5.1

* `Grape::Entity::Exposure::NestingExposure::NestedExposures.delete_if` always
returns exposures, regardless of delete result (used to be
`nil` in negative case), see [#203](https://github.com/ruby-grape/grape-entity/pull/203).
