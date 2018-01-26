# Grape::Entity

[![Gem Version](http://img.shields.io/gem/v/grape-entity.svg)](http://badge.fury.io/rb/grape-entity)
[![Build Status](http://img.shields.io/travis/ruby-grape/grape-entity.svg)](https://travis-ci.org/ruby-grape/grape-entity)
[![Coverage Status](https://coveralls.io/repos/github/ruby-grape/grape-entity/badge.svg?branch=master)](https://coveralls.io/github/ruby-grape/grape-entity?branch=master)
[![Dependency Status](https://gemnasium.com/ruby-grape/grape-entity.svg)](https://gemnasium.com/ruby-grape/grape-entity)
[![Code Climate](https://codeclimate.com/github/ruby-grape/grape-entity.svg)](https://codeclimate.com/github/ruby-grape/grape-entity)

## Introduction

This gem adds Entity support to API frameworks, such as [Grape](https://github.com/ruby-grape/grape). Grape's Entity is an API focused facade that sits on top of an object model.

### Example

```ruby
module API
  module Entities
    class Status < Grape::Entity
      format_with(:iso_timestamp) { |dt| dt.iso8601 }

      expose :user_name
      expose :text, documentation: { type: "String", desc: "Status update text." }
      expose :ip, if: { type: :full }
      expose :user_type, :user_id, if: lambda { |status, options| status.user.public? }
      expose :location, merge: true
      expose :contact_info do
        expose :phone
        expose :address, merge: true, using: API::Entities::Address
      end
      expose :digest do |status, options|
        Digest::MD5.hexdigest status.txt
      end
      expose :replies, using: API::Entities::Status, as: :responses
      expose :last_reply, using: API::Entities::Status do |status, options|
        status.replies.last
      end

      with_options(format_with: :iso_timestamp) do
        expose :created_at
        expose :updated_at
      end
    end
  end
end

module API
  module Entities
    class StatusDetailed < API::Entities::Status
      expose :internal_id
    end
  end
end
```

## Reusable Responses with Entities

Entities are a reusable means for converting Ruby objects to API responses. Entities can be used to conditionally include fields, nest other entities, and build ever larger responses, using inheritance.

### Defining Entities

Entities inherit from Grape::Entity, and define a simple DSL. Exposures can use runtime options to determine which fields should be visible, these options are available to `:if`, `:unless`, and `:proc`.

#### Basic Exposure

Define a list of fields that will always be exposed.

```ruby
expose :user_name, :ip
```

The field lookup takes several steps

* first try `entity-instance.exposure`
* next try `object.exposure`
* next try `object.fetch(exposure)`
* last raise an Exception

#### Exposing with a Presenter

Don't derive your model classes from `Grape::Entity`, expose them using a presenter.

```ruby
expose :replies, using: API::Entities::Status, as: :responses
```

Presenter classes can also be specified in string format, which helps with circular dependencies.

```ruby
expose :replies, using: "API::Entities::Status", as: :responses
```

#### Conditional Exposure

Use `:if` or `:unless` to expose fields conditionally.

```ruby
expose :ip, if: { type: :full }

expose :ip, if: lambda { |instance, options| options[:type] == :full } # exposed if the function evaluates to true
expose :ip, if: :type # exposed if :type is available in the options hash
expose :ip, if: { type: :full } # exposed if options :type has a value of :full

expose :ip, unless: ... # the opposite of :if
```

#### Safe Exposure

Don't raise an exception and expose as nil, even if the :x cannot be evaluated.

```ruby
expose :ip, safe: true
```

#### Nested Exposure

Supply a block to define a hash using nested exposures.

```ruby
expose :contact_info do
  expose :phone
  expose :address, using: API::Entities::Address
end
```

You can also conditionally expose attributes in nested exposures:
```ruby
expose :contact_info do
  expose :phone
  expose :address, using: API::Entities::Address
  expose :email, if: lambda { |instance, options| options[:type] == :full }
end
```


#### Collection Exposure

Use `root(plural, singular = nil)` to expose an object or a collection of objects with a root key.

```ruby
root 'users', 'user'
expose :id, :name, ...
```

By default every object of a collection is wrapped into an instance of your `Entity` class.
You can override this behavior and wrap the whole collection into one instance of your `Entity`
class.

As example:

```ruby

 present_collection true, :collection_name  # `collection_name` is optional and defaults to `items`
 expose :collection_name, using: API::Entities::Items


```

#### Merge Fields

Use `:merge` option to merge fields into the hash or into the root:

```ruby
expose :contact_info do
  expose :phone
  expose :address, merge: true, using: API::Entities::Address
end

expose :status, merge: true
```

This will return something like:

```ruby
{ contact_info: { phone: "88002000700", city: 'City 17', address_line: 'Block C' }, text: 'HL3', likes: 19 }
```

It also works with collections:

```ruby
expose :profiles do
  expose :users, merge: true, using: API::Entities::User
  expose :admins, merge: true, using: API::Entities::Admin
end
```

Provide lambda to solve collisions:

```ruby
expose :status, merge: ->(key, old_val, new_val) { old_val + new_val if old_val && new_val }
```

#### Runtime Exposure

Use a block or a `Proc` to evaluate exposure at runtime. The supplied block or
`Proc` will be called with two parameters: the represented object and runtime options.

**NOTE:** A block supplied with no parameters will be evaluated as a nested exposure (see above).

```ruby
expose :digest do |status, options|
  Digest::MD5.hexdigest status.txt
end
```

```ruby
expose :digest, proc: ... # equivalent to a block
```

You can also define a method on the entity and it will try that before trying
on the object the entity wraps.

```ruby
class ExampleEntity < Grape::Entity
  expose :attr_not_on_wrapped_object
  # ...
  private

  def attr_not_on_wrapped_object
    42
  end
end
```

You have always access to the presented instance with `object`

```ruby
class ExampleEntity < Grape::Entity
  expose :formatted_value
  # ...
  private

  def formatted_value
    "+ X #{object.value}"
  end
end
```

#### Unexpose

To undefine an exposed field, use the ```.unexpose``` method. Useful for modifying inherited entities.

```ruby
class UserData < Grape::Entity
  expose :name
  expose :address1
  expose :address2
  expose :address_state
  expose :address_city
  expose :email
  expose :phone
end

class MailingAddress < UserData
  unexpose :email
  unexpose :phone
end
```

#### Overriding exposures

If you want to add one more exposure for the field but don't want the first one to be fired (for instance, when using inheritance), you can use the `override` flag. For instance:

```ruby
class User < Grape::Entity
  expose :name
end

class Employee < UserData
  expose :name, as: :employee_name, override: true
end
```

`User` will return something like this `{ "name" : "John" }` while `Employee` will present the same data as `{ "employee_name" : "John" }` instead of `{ "name" : "John", "employee_name" : "John" }`.

#### Returning only the fields you want

After exposing the desired attributes, you can choose which one you need when representing some object or collection by using the only: and except: options. See the example:

```ruby
class UserEntity
  expose :id
  expose :name
  expose :email
end

class Entity
  expose :id
  expose :title
  expose :user, using: UserEntity
end

data = Entity.represent(model, only: [:title, { user: [:name, :email] }])
data.as_json
```

This will return something like this:

```ruby
{
  title: 'grape-entity is awesome!',
  user: {
    name: 'John Applet',
    email: 'john@example.com'
  }
}
```

Instead of returning all the exposed attributes.


The same result can be achieved with the following exposure:

```ruby
data = Entity.represent(model, except: [:id, { user: [:id] }])
data.as_json
```

#### Aliases

Expose under a different name with `:as`.

```ruby
expose :replies, using: API::Entities::Status, as: :responses
```

#### Format Before Exposing

Apply a formatter before exposing a value.

```ruby
module Entities
  class MyModel < Grape::Entity
    format_with(:iso_timestamp) do |date|
      date.iso8601
    end

    with_options(format_with: :iso_timestamp) do
      expose :created_at
      expose :updated_at
    end
  end
end
```

Defining a reusable formatter between multiples entities:

```ruby
module ApiHelpers
  extend Grape::API::Helpers

  Grape::Entity.format_with :utc do |date|
    date.utc if date
  end
end
```

```ruby
module Entities
  class MyModel < Grape::Entity
    expose :updated_at, format_with: :utc
  end

  class AnotherModel < Grape::Entity
    expose :created_at, format_with: :utc
  end
end
```

#### Expose Nil

By default, exposures that contain `nil` values will be represented in the resulting JSON as `null`.

As an example, a hash with the following values:

```ruby
{
  name: nil,
  age: 100
}
```

will result in a JSON object that looks like:

```javascript
{
  "name": null,
  "age": 100
}
```

There are also times when, rather than displaying an attribute with a `null` value, it is more desirable to not display the attribute at all. Using the hash from above the desired JSON would look like:

```javascript
{
  "age": 100
}
```

In order to turn on this behavior for an as-exposure basis, the option `expose_nil` can be used. By default, `expose_nil` is considered to be `true`, meaning that `nil` values will be represented in JSON as `null`. If `false` is provided, then attributes with `nil` values will be omitted from the resulting JSON completely.

```ruby
module  Entities
  class MyModel < Grape::Entity
    expose :name, expose_nil: false
    expose :age, expose_nil: false
  end
end
```

`expose_nil` is per exposure, so you can suppress exposures from resulting in `null` or express `null` values on a per exposure basis as you need:

```ruby
module  Entities
  class MyModel < Grape::Entity
    expose :name, expose_nil: false
    expose :age # since expose_nil is omitted nil values will be rendered as null
  end
end
```

It is also possible to use `expose_nil` with `with_options` if you want to add the configuration to multiple exposures at once.

```ruby
module  Entities
  class MyModel < Grape::Entity
    # None of the exposures in the with_options block will render nil values as null
    with_options(expose_nil: false) do
      expose :name
      expose :age
    end
  end
end
```

When using `with_options`, it is possible to again override which exposures will render `nil` as `null` by adding the option on a specific exposure.

```ruby
module  Entities
  class MyModel < Grape::Entity
    # None of the exposures in the with_options block will render nil values as null
    with_options(expose_nil: false) do
      expose :name
      expose :age, expose_nil: true # nil values would be rendered as null in the JSON
    end
  end
end
```

#### Documentation

Expose documentation with the field. Gets bubbled up when used with Grape and various API documentation systems.

```ruby
expose :text, documentation: { type: "String", desc: "Status update text." }
```

### Options Hash

The option keys `:version` and `:collection` are always defined. The `:version` key is defined as `api.version`. The `:collection` key is boolean, and defined as `true` if the object presented is an array. The options also contain the runtime environment in `:env`, which includes request parameters in `options[:env]['grape.request.params']`.

Any additional options defined on the entity exposure are included as is. In the following example `user` is set to the value of `current_user`.

```ruby
class Status < Grape::Entity
  expose :user, if: lambda { |instance, options| options[:user] } do |instance, options|
    # examine available environment keys with `p options[:env].keys`
    options[:user]
  end
end
```

```
present s, with: Status, user: current_user
```

#### Passing Additional Option To Nested Exposure
Sometimes you want to pass additional options or parameters to nested a exposure. For example, let's say that you need to expose an address for a contact info and it has two different formats: **full** and **simple**. You can pass an additional `full_format` option to specify which format to render.

```ruby
# api/contact.rb
expose :contact_info do
  expose :phone
  expose :address do |instance, options|
    # use `#merge` to extend options and then pass the new version of options to the nested entity
    API::Entities::Address.represent instance.address, options.merge(full_format: instance.need_full_format?)
  end
  expose :email, if: lambda { |instance, options| options[:type] == :full }
end

# api/address.rb
expose :state, if: lambda {|instance, options| !!options[:full_format]}      # the new option could be retrieved in options hash for conditional exposure
expose :city, if: lambda {|instance, options| !!options[:full_format]}
expose :street do |instance, options|
  # the new option could be retrieved in options hash for runtime exposure
  !!options[:full_format] ? instance.full_street_name : instance.simple_street_name
end
```
**Notice**: In the above code, you should pay attention to [**Safe Exposure**](#safe-exposure) yourself. For example, `instance.address` might be `nil`  and it is better to expose it as nil directly.

#### Attribute Path Tracking

Sometimes, especially when there are nested attributes, you might want to know which attribute
is being exposed. For example, some APIs allow users to provide a parameter to control which fields
will be included in (or excluded from) the response.

GrapeEntity can track the path of each attribute, which you can access during conditions checking
or runtime exposure via `options[:attr_path]`.

The attribute path is an array. The last item of this array is the name (alias) of current attribute.
If the attribute is nested, the former items are names (aliases) of its ancestor attributes.

Example:

```ruby
class Status < Grape::Entity
  expose :user  # path is [:user]
  expose :foo, as: :bar  # path is [:bar]
  expose :a do
    expose :b, as: :xx do
      expose :c  # path is [:a, :xx, :c]
    end
  end
end
```

### Using the Exposure DSL

Grape ships with a DSL to easily define entities within the context of an existing class:

```ruby
class Status
  include Grape::Entity::DSL

  entity :text, :user_id do
    expose :detailed, if: :conditional
  end
end
```

The above will automatically create a `Status::Entity` class and define properties on it according to the same rules as above. If you only want to define simple exposures you don't have to supply a block and can instead simply supply a list of comma-separated symbols.

### Using Entities

With Grape, once an entity is defined, it can be used within endpoints, by calling `present`. The `present` method accepts two arguments, the `object` to be presented and the `options` associated with it. The options hash must always include `:with`, which defines the entity to expose (unless namespaced entity classes are used, see [next section](#entity-organization)).
If the entity includes documentation it can be included in an endpoint's description.

```ruby
module API
  class Statuses < Grape::API
    version 'v1'

    desc 'Statuses.', {
      params: API::Entities::Status.documentation
    }
    get '/statuses' do
      statuses = Status.all
      type = current_user.admin? ? :full : :default
      present statuses, with: API::Entities::Status, type: type
    end
  end
end
```

### Entity Organization

In addition to separately organizing entities, it may be useful to put them as namespaced classes underneath the model they represent.

```ruby
class Status
  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :text, :user_id
  end
end
```

If you organize your entities this way, Grape will automatically detect the `Entity` class and use it to present your models. In this example, if you added `present Status.new` to your endpoint, Grape would automatically detect that there is a `Status::Entity` class and use that as the representative entity. This can still be overridden by using the `:with` option or an explicit `represents` call.

### Caveats

Entities with duplicate exposure names and conditions will silently overwrite one another. In the following example, when `object.check` equals "foo", only `field_a` will be exposed. However, when `object.check` equals "bar" both `field_b` and `foo` will be exposed.

```ruby
module API
  module Entities
    class Status < Grape::Entity
      expose :field_a, :foo, if: lambda { |object, options| object.check == "foo" }
      expose :field_b, :foo, if: lambda { |object, options| object.check == "bar" }
    end
  end
end
```

This can be problematic, when you have mixed collections. Using `respond_to?` is safer.

```ruby
module API
  module Entities
    class Status < Grape::Entity
      expose :field_a, if: lambda { |object, options| object.check == "foo" }
      expose :field_b, if: lambda { |object, options| object.check == "bar" }
      expose :foo, if: lambda { |object, options| object.respond_to?(:foo) }
    end
  end
end
```

Also note that an `ArgumentError` is raised when unknown options are passed to either `expose` or `with_options`.

## Installation

Add this line to your application's Gemfile:

    gem 'grape-entity'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grape-entity

## Testing with Entities

Test API request/response as usual.

Also see [Grape Entity Matchers](https://github.com/agileanimal/grape-entity-matchers).

## Project Resources

* Need help? [Grape Google Group](http://groups.google.com/group/ruby-grape)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License. See [LICENSE](LICENSE) for details.

## Copyright

Copyright (c) 2010-2016 Michael Bleigh, Intridea, Inc., ruby-grape and Contributors.
