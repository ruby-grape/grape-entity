# Grape::Entity

[![Build Status](https://travis-ci.org/agileanimal/grape-entity.png?branch=master)](https://travis-ci.org/agileanimal/grape-entity)

## Introduction

This gem adds Entity support to API frameworks, such as [Grape](https://github.com/intridea/grape). Grape's Entity is an API focussed facade that sits on top of an object model.

## What's New 

We are currently working on a set of "shoulda-style matchers" (sorry, RSpec only right now -- although they've been done in a way that can support test-unit in the future).

[Grape Entity Matchers](https://github.com/agileanimal/grape-entity-matchers).

This is still a work in progress but worth checking out.

## Reusable Responses with Entities

Entities are a reusable means for converting Ruby objects to API responses.
Entities can be used to conditionally include fields, nest other entities, and build
ever larger responses, using inheritance.

### Defining Entities

Entities inherit from Grape::Entity, and define a simple DSL. Exposures can use
runtime options to determine which fields should be visible, these options are
available to `:if`, `:unless`, and `:proc`. The option keys `:version` and `:collection`
will always be defined. The `:version` key is defined as `api.version`. The
`:collection` key is boolean, and defined as `true` if the object presented is an
array.

  * `expose SYMBOLS`
    * define a list of fields which will always be exposed
  * `expose SYMBOLS, HASH`
    * HASH keys include `:if`, `:unless`, `:proc`, `:as`, `:using`, `:format_with`, `:documentation`
      * `:if` and `:unless` accept hashes (passed during runtime), procs (arguments are object and options), or symbols (checks for presence of the specified key on the options hash)
  * `expose SYMBOL, { :format_with => :formatter }`
    * expose a value, formatting it first
    * `:format_with` can only be applied to one exposure at a time
  * `expose SYMBOL, { :as => "alias" }`
    * Expose a value, changing its hash key from SYMBOL to alias
    * `:as` can only be applied to one exposure at a time
  * `expose SYMBOL BLOCK`
    * block arguments are object and options
    * expose the value returned by the block
    * block can only be applied to one exposure at a time

```ruby
module API
  module Entities
    class Status < Grape::Entity
      expose :user_name
      expose :text, :documentation => { :type => "string", :desc => "Status update text." }
      expose :ip, :if => { :type => :full }
      expose :user_type, user_id, :if => lambda{ |status, options| status.user.public? }
      expose :digest { |status, options| Digest::MD5.hexdigest(satus.txt) }
      expose :replies, :using => API::Status, :as => :replies
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

#### Using the Exposure DSL

Grape ships with a DSL to easily define entities within the context
of an existing class:

```ruby
class Status
  include Grape::Entity::DSL

  entity :text, :user_id do
    expose :detailed, if: :conditional
  end
end
```

The above will automatically create a `Status::Entity` class and define properties on it according
to the same rules as above. If you only want to define simple exposures you don't have to supply
a block and can instead simply supply a list of comma-separated symbols.

### Using Entities

Once an entity is defined, it can be used within endpoints, by calling `present`. The `present`
method accepts two arguments, the object to be presented and the options associated with it. The
options hash must always include `:with`, which defines the entity to expose.

If the entity includes documentation it can be included in an endpoint's description.

```ruby
module API
  class Statuses < Grape::API
    version 'v1'

    desc 'Statuses index', {
      :object_fields => API::Entities::Status.documentation
    }
    get '/statuses' do
      statuses = Status.all
      type = current_user.admin? ? :full : :default
      present statuses, with: API::Entities::Status, :type => type
    end
  end
end
```

### Entity Organization

In addition to separately organizing entities, it may be useful to put them as namespaced
classes underneath the model they represent.

```ruby
class Status
  def entity
    Status.new(self)
  end

  class Entity < Grape::Entity
    expose :text, :user_id
  end
end
```

If you organize your entities this way, Grape will automatically detect the `Entity` class and
use it to present your models. In this example, if you added `present User.new` to your endpoint,
Grape would automatically detect that there is a `Status::Entity` class and use that as the
representative entity. This can still be overridden by using the `:with` option or an explicit
`represents` call.

### Caveats

Entities with duplicate exposure names and conditions will silently overwrite one another.
In the following example, when `object.check` equals "foo", only `field_a` will be exposed.
However, when `object.check` equals "bar" both `field_b` and `foo` will be exposed.

```ruby
module API
  module Entities
    class Status < Grape::Entity
      expose :field_a, :foo, :if => lambda { |object, options| object.check == "foo" }
      expose :field_b, :foo, :if => lambda { |object, options| object.check == "bar" }
    end
  end
end
```

This can be problematic, when you have mixed collections. Using `respond_to?` is safer.

```ruby
module API
  module Entities
    class Status < Grape::Entity
      expose :field_a, :if => lambda { |object, options| object.check == "foo" }
      expose :field_b, :if => lambda { |object, options| object.check == "bar" }
      expose :foo, :if => lambda { |object, options| object.respond_to?(:foo) }
    end
  end
end
```

## Installation

Add this line to your application's Gemfile:

    gem 'grape-entity'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grape-entity

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

MIT License. See LICENSE for details.

## Copyright

Copyright (c) 2010-2013 Michael Bleigh, and Intridea, Inc.
