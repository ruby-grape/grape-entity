### 0.6.0 (2016-11-20)

#### Features

* [#247](https://github.com/ruby-grape/grape-entity/pull/247): Updates dependencies; refactores to make specs green - [@LeFnord](https://github.com/LeFnord).

#### Fixes

* [#249](https://github.com/ruby-grape/grape-entity/issues/249): Fix leaking of options and internals in default serialization - [@dblock](https://github.com/dblock), [@KingsleyKelly](https://github.com/KingsleyKelly).
* [#248](https://github.com/ruby-grape/grape-entity/pull/248): Fix `nil` values causing errors when `merge` option passed - [@arempe93](https://github.com/arempe93).

### 0.5.2 (2016-11-14)

#### Features

* [#226](https://github.com/ruby-grape/grape-entity/pull/226): Added `fetch` from `opts_hash` - [@alanjcfs](https://github.com/alanjcfs).
* [#232](https://github.com/ruby-grape/grape-entity/pull/232), [#213](https://github.com/ruby-grape/grape-entity/issues/213): Added `#kind_of?` and `#is_a?` to `OutputBuilder` to get an exact class of an `output` object - [@avyy](https://github.com/avyy).
* [#234](https://github.com/ruby-grape/grape-entity/pull/234), [#233](https://github.com/ruby-grape/grape-entity/issues/233): Added ruby version checking in `Gemfile` to install needed gems versions for supporting old rubies too - [@avyy](https://github.com/avyy).
* [#237](https://github.com/ruby-grape/grape-entity/pull/237): Added Danger, PR linter - [@dblock](https://github.com/dblock).

#### Fixes

* [#215](https://github.com/ruby-grape/grape-entity/pull/217): `#delegate_attribute` no longer delegates to methods included with `Kernel` - [@maltoe](https://github.com/maltoe).
* [#219](https://github.com/ruby-grape/grape-entity/pull/219): Double pass options in `serializable_hash` - [@sbatykov](https://github.com/sbatykov).
* [#231](https://github.com/ruby-grape/grape-entity/pull/231), [#215](https://github.com/ruby-grape/grape-entity/issues/215): Allow `delegate_attribute` for derived entity - [@sbatykov](https://github.com/sbatykov).

### 0.5.1 (2016-4-4)

#### Features

* [#203](https://github.com/ruby-grape/grape-entity/pull/203): `Grape::Entity::Exposure::NestingExposure::NestedExposures.delete_if` always returns exposures - [@rngtng](https://github.com/rngtng).
* [#204](https://github.com/ruby-grape/grape-entity/pull/204), [#138](https://github.com/ruby-grape/grape-entity/issues/138): Added ability to merge fields into hashes/root (`:merge` option for `.expose`) - [@avyy](https://github.com/avyy).

#### Fixes

* [#202](https://github.com/ruby-grape/grape-entity/pull/202): Reset `@using_class` memoization on `.setup` - [@rngtng](https://github.com/rngtng).

### 0.5.0 (2015-12-07)

#### Features

* [#139](https://github.com/ruby-grape/grape-entity/pull/139): Keep a track of attribute nesting path during condition check or runtime exposure - [@calfzhou](https://github.com/calfzhou).
* [#151](https://github.com/ruby-grape/grape-entity/pull/151): `.exposures` is removed and substituted with `.root_exposures` array - [@marshall-lee](https://github.com/marshall-lee).
* [#151](https://github.com/ruby-grape/grape-entity/pull/151): `.nested_exposures` is removed too - [@marshall-lee](https://github.com/marshall-lee).
* [#151](https://github.com/ruby-grape/grape-entity/pull/151): `#should_return_attribute?`, `#only_fields` and `#except_fields` are moved to other classes - [@marshall-lee](https://github.com/marshall-lee).
* [#151](https://github.com/ruby-grape/grape-entity/pull/151): Nested `unexpose` now raises an exception: [#152](https://github.com/ruby-grape/grape-entity/issues/152) - [@marshall-lee](https://github.com/marshall-lee).

#### Fixes

* [#151](https://github.com/ruby-grape/grape-entity/pull/151): Double exposures with conditions does not rewrite previously defined now: [#56](https://github.com/ruby-grape/grape-entity/issues/56) - [@marshall-lee](https://github.com/marshall-lee).
* [#151](https://github.com/ruby-grape/grape-entity/pull/151): Nested exposures were flattened in `.documentation`: [#112](https://github.com/ruby-grape/grape-entity/issues/112) - [@marshall-lee](https://github.com/marshall-lee).
* [#151](https://github.com/ruby-grape/grape-entity/pull/151): `@only_fields` and `@except_fields` memoization: [#149](https://github.com/ruby-grape/grape-entity/issues/149) - [@marshall-lee](https://github.com/marshall-lee).
* [#151](https://github.com/ruby-grape/grape-entity/pull/151): `:unless` condition with `Hash` argument logic: [#150](https://github.com/ruby-grape/grape-entity/issues/150) - [@marshall-lee](https://github.com/marshall-lee).
* [#151](https://github.com/ruby-grape/grape-entity/pull/151): `@documentation` memoization: [#153](https://github.com/ruby-grape/grape-entity/issues/153) - [@marshall-lee](https://github.com/marshall-lee).
* [#151](https://github.com/ruby-grape/grape-entity/pull/151): Serializing of deeply nested presenter exposures: [#155](https://github.com/ruby-grape/grape-entity/issues/155) - [@marshall-lee](https://github.com/marshall-lee).
* [#151](https://github.com/ruby-grape/grape-entity/pull/151): Deep projections (`:only`, `:except`) were unaware of nesting: [#156](https://github.com/ruby-grape/grape-entity/issues/156) - [@marshall-lee](https://github.com/marshall-lee).

### 0.4.8 (2015-08-10)

#### Features

* [#167](https://github.com/ruby-grape/grape-entity/pull/167), [#166](https://github.com/ruby-grape/grape-entity/issues/166): Regression with global settings (exposures, formatters) on `Grape::Entity` - [@marshall-lee](https://github.com/marshall-lee).

### 0.4.7 (2015-08-03)

#### Features

* [#164](https://github.com/ruby-grape/grape-entity/pull/164): Regression: entity instance methods were exposed with `NoMethodError`: [#163](https://github.com/ruby-grape/grape-entity/issues/163) - [@marshall-lee](https://github.com/marshall-lee).

### 0.4.6 (2015-07-27)

#### Features

* [#114](https://github.com/ruby-grape/grape-entity/pull/114): Added 'only' option that selects which attributes should be returned - [@estevaoam](https://github.com/estevaoam).
* [#115](https://github.com/ruby-grape/grape-entity/pull/115): Allowing 'root' to be inherited from parent to child entities - [@guidoprincess](https://github.com/guidoprincess).
* [#121](https://github.com/ruby-grape/grape-entity/pull/122): Sublcassed Entity#documentation properly handles unexposed params - [@dan-corneanu](https://github.com/dan-corneanu).
* [#134](https://github.com/ruby-grape/grape-entity/pull/134): Subclasses no longer affected in all cases by `unexpose` in parent - [@etehtsea](https://github.com/etehtsea).
* [#135](https://github.com/ruby-grape/grape-entity/pull/135): Added `except` option - [@dan-corneanu](https://github.com/dan-corneanu).
* [#136](https://github.com/ruby-grape/grape-entity/pull/136): Allow for strings in `only` and `except` options - [@bswinnerton](https://github.com/bswinnerton).
* [#147](https://github.com/ruby-grape/grape-entity/pull/147), [#140](https://github.com/ruby-grape/grape-entity/issues/140): Expose `safe` attributes as `nil` if they cannot be evaluated - [@marshall-lee](https://github.com/marshall-lee).
* [#147](https://github.com/ruby-grape/grape-entity/pull/147): Remove catching of `NoMethodError` because it can occur deep inside in a method call so this exception does not mean that attribute not exist - [@marshall-lee](https://github.com/marshall-lee).
* [#147](https://github.com/ruby-grape/grape-entity/pull/147): The `valid_exposures` method was removed - [@marshall-lee](https://github.com/marshall-lee).

#### Fixes

* [#147](https://github.com/ruby-grape/grape-entity/pull/147), [#142](https://github.com/ruby-grape/grape-entity/pull/142): Private method values were not exposed with `safe` option - [@marshall-lee](https://github.com/marshall-lee).

### 0.4.5 (2015-03-10)

#### Features

* [#109](https://github.com/ruby-grape/grape-entity/pull/109): Added `unexpose` method - [@jonmchan](https://github.com/jonmchan).
* [#98](https://github.com/ruby-grape/grape-entity/pull/98): Added nested conditionals - [@zbelzer](https://github.com/zbelzer).
* [#105](https://github.com/ruby-grape/grape-entity/pull/105): Specify which attribute is missing in which Entity - [@jhollinger](https://github.com/jhollinger).

#### Fixes

* [#111](https://github.com/ruby-grape/grape-entity/pull/111): Allow usage of attributes with name 'key' if `Hash` objects are used - [@croeck](https://github.com/croeck).
* [#110](https://github.com/ruby-grape/grape-entity/pull/110): Safe exposure when using `Hash` models - [@croeck](https://github.com/croeck).
* [#91](https://github.com/ruby-grape/grape-entity/pull/91): OpenStruct serializing - [@etehtsea](https://github.com/etehtsea).

### 0.4.4 (2014-08-17)

#### Features

* [#85](https://github.com/ruby-grape/grape-entity/pull/85): Added `present_collection` to indicate that an `Entity` presents an entire Collection - [@dspaeth-faber](https://github.com/dspaeth-faber).
* [#85](https://github.com/ruby-grape/grape-entity/pull/85): Hashes can now be passed as object to be presented and the `Hash` keys can be referenced by expose - [@dspaeth-faber](https://github.com/dspaeth-faber).

### 0.4.3 (2014-06-12)

#### Features

* [#76](https://github.com/ruby-grape/grape-entity/pull/76): Improve performance of entity serialization - [@justfalter](https://github.com/justfalter).

#### Fixes

* [#77](https://github.com/ruby-grape/grape-entity/pull/77): Compatibility with Rspec 3 - [@justfalter](https://github.com/justfalter).

### 0.4.2 (2014-04-03)

#### Features

* [#60](https://github.com/ruby-grape/grape-entity/issues/59): Performance issues introduced by nested exposures - [@AlexYankee](https://github.com/AlexYankee).
* [#60](https://github.com/ruby-grape/grape-entity/issues/57): Nested exposure double-exposes a field - [@AlexYankee](https://github.com/AlexYankee).

### 0.4.1 (2014-02-13)

#### Fixes

* [#54](https://github.com/ruby-grape/grape-entity/issues/54): Fix: undefined method `to_set` - [@aj0strow](https://github.com/aj0strow).

### 0.4.0 (2014-01-27)

#### Features

* Ruby 1.8.x is no longer supported - [@dblock](https://github.com/dblock).
* [#36](https://github.com/ruby-grape/grape-entity/pull/36): Enforcing Ruby style guidelines via Rubocop - [@dblock](https://github.com/dblock).
* [#7](https://github.com/ruby-grape/grape-entity/issues/7): Added `serializable` option to `represent` - [@mbleigh](https://github.com/mbleigh).
* [#18](https://github.com/ruby-grape/grape-entity/pull/18): Added `safe` option to `expose`, will not raise error for a missing attribute - [@fixme](https://github.com/fixme).
* [#16](https://github.com/ruby-grape/grape-entity/pull/16): Added `using` option to `expose SYMBOL BLOCK` - [@fahchen](https://github.com/fahchen).
* [#24](https://github.com/ruby-grape/grape-entity/pull/24): Return documentation with `as` param considered - [@drakula2k](https://github.com/drakula2k).
* [#27](https://github.com/ruby-grape/grape-entity/pull/27): Properly serialize hashes - [@clintonb](https://github.com/clintonb).
* [#28](https://github.com/ruby-grape/grape-entity/pull/28): Look for method on entity before calling it on the object - [@MichaelXavier](https://github.com/MichaelXavier).
* [#33](https://github.com/ruby-grape/grape-entity/pull/33): Support proper merging of nested conditionals - [@wyattisimo](https://github.com/wyattisimo).
* [#43](https://github.com/ruby-grape/grape-entity/pull/43): Call procs in context of entity instance - [@joelvh](https://github.com/joelvh).
* [#47](https://github.com/ruby-grape/grape-entity/pull/47): Support nested exposures - [@wyattisimo](https://github.com/wyattisimo).
* [#46](https://github.com/ruby-grape/grape-entity/issues/46), [#50](https://github.com/ruby-grape/grape-entity/pull/50): Added support for specifying the presenter class in `using` in string format - [@larryzhao](https://github.com/larryzhao).
* [#51](https://github.com/ruby-grape/grape-entity/pull/51): Raise `ArgumentError` if an unknown option is used with `expose` - [@aj0strow](https://github.com/aj0strow).
* [#51](https://github.com/ruby-grape/grape-entity/pull/51): Alias `:with` to `:using`, consistently with the Grape api endpoints - [@aj0strow](https://github.com/aj0strow).

### 0.3.0 (2013-03-29)

#### Features

* [#9](https://github.com/ruby-grape/grape-entity/pull/9): Added `with_options` for block-level exposure setting - [@SegFaultAX](https://github.com/SegFaultAX).
* The `instance.entity` method now optionally accepts `options` - [@mbleigh](https://github.com/mbleigh).
* You can pass symbols to `:if` and `:unless` to simply check for truthiness/falsiness of the specified options key - [@mbleigh](https://github.com/mbleigh).

### 0.2.0 (2013-01-11)

#### Features

* Moved the namespace back to `Grape::Entity` to preserve compatibility with Grape - [@dblock](https://github.com/dblock).

### 0.1.0 (2013-01-11)

* Initial public release - [@agileanimal](https://github.com/agileanimal).
