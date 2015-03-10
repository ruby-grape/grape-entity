0.4.5 (2015-03-10)
==================

* [#109](https://github.com/intridea/grape-entity/pull/109): Added `unexpose` method - [@jonmchan](https://github.com/jonmchan).
* [#98](https://github.com/intridea/grape-entity/pull/98): Added nested conditionals - [@zbelzer](https://github.com/zbelzer).
* [#105](https://github.com/intridea/grape-entity/pull/105): Specify which attribute is missing in which Entity - [@jhollinger](https://github.com/jhollinger).
* [#111](https://github.com/intridea/grape-entity/pull/111): Fix: allow usage of attributes with name 'key' if `Hash` objects are used - [@croeck](https://github.com/croeck).
* [#110](https://github.com/intridea/grape-entity/pull/110): Fix: safe exposure when using `Hash` models - [@croeck](https://github.com/croeck).
* [#91](https://github.com/intridea/grape-entity/pull/91): Fix: OpenStruct serializing - [@etehtsea](https://github.com/etehtsea).

0.4.4 (2014-08-17)
==================

* [#85](https://github.com/intridea/grape-entity/pull/85): Added `present_collection` to indicate that an `Entity` presents an entire Collection - [@dspaeth-faber](https://github.com/dspaeth-faber).
* [#85](https://guthub.com/intridea/grape-entity/pull/85): Hashes can now be passed as object to be presented and the `Hash` keys can be referenced by expose - [@dspaeth-faber](https://github.com/dspaeth-faber).

0.4.3 (2014-06-12)
==================

* [#77](https://github.com/intridea/grape-entity/pull/77): Fix: compatibility with Rspec 3 - [@justfalter](https://github.com/justfalter).
* [#76](https://github.com/intridea/grape-entity/pull/76): Improve performance of entity serialization - [@justfalter](https://github.com/justfalter)

0.4.2 (2014-04-03)
==================

* [#60](https://github.com/intridea/grape-entity/issues/59): Performance issues introduced by nested exposures - [@AlexYankee](https://github.com/AlexYankee).
* [#60](https://github.com/intridea/grape-entity/issues/57): Nested exposure double-exposes a field - [@AlexYankee](https://github.com/AlexYankee).

0.4.1 (2014-02-13)
==================

* [#54](https://github.com/intridea/grape-entity/issues/54): Fix: undefined method `to_set` - [@aj0strow](https://github.com/aj0strow).

0.4.0 (2014-01-27)
==================

* Ruby 1.8.x is no longer supported - [@dblock](https://github.com/dblock).
* [#36](https://github.com/intridea/grape-entity/pull/36): Enforcing Ruby style guidelines via Rubocop - [@dblock](https://github.com/dblock).
* [#7](https://github.com/intridea/grape-entity/issues/7): Added `serializable` option to `represent` - [@mbleigh](https://github.com/mbleigh).
* [#18](https://github.com/intridea/grape-entity/pull/18): Added `safe` option to `expose`, will not raise error for a missing attribute - [@fixme](https://github.com/fixme).
* [#16](https://github.com/intridea/grape-entity/pull/16): Added `using` option to `expose SYMBOL BLOCK` - [@fahchen](https://github.com/fahchen).
* [#24](https://github.com/intridea/grape-entity/pull/24): Return documentation with `as` param considered - [@drakula2k](https://github.com/drakula2k).
* [#27](https://github.com/intridea/grape-entity/pull/27): Properly serialize hashes - [@clintonb](https://github.com/clintonb).
* [#28](https://github.com/intridea/grape-entity/pull/28): Look for method on entity before calling it on the object - [@MichaelXavier](https://github.com/MichaelXavier).
* [#33](https://github.com/intridea/grape-entity/pull/33): Support proper merging of nested conditionals - [@wyattisimo](https://github.com/wyattisimo).
* [#43](https://github.com/intridea/grape-entity/pull/43): Call procs in context of entity instance - [@joelvh](https://github.com/joelvh).
* [#47](https://github.com/intridea/grape-entity/pull/47): Support nested exposures - [@wyattisimo](https://github.com/wyattisimo).
* [#46](https://github.com/intridea/grape-entity/issues/46), [#50](https://github.com/intridea/grape-entity/pull/50): Added support for specifying the presenter class in `using` in string format - [@larryzhao](https://github.com/larryzhao).
* [#51](https://github.com/intridea/grape-entity/pull/51): Raise `ArgumentError` if an unknown option is used with `expose` - [@aj0strow](https://github.com/aj0strow).
* [#51](https://github.com/intridea/grape-entity/pull/51): Alias `:with` to `:using`, consistently with the Grape api endpoints - [@aj0strow](https://github.com/aj0strow).

0.3.0 (2013-03-29)
==================

* [#9](https://github.com/intridea/grape-entity/pull/9): Added `with_options` for block-level exposure setting - [@SegFaultAX](https://github.com/SegFaultAX).
* The `instance.entity` method now optionally accepts `options` - [@mbleigh](https://github.com/mbleigh).
* You can pass symbols to `:if` and `:unless` to simply check for truthiness/falsiness of the specified options key - [@mbleigh](https://github.com/mbleigh).

0.2.0 (2013-01-11)
==================

* Moved the namespace back to `Grape::Entity` to preserve compatibility with Grape - [@dblock](https://github.com/dblock).

0.1.0 (2013-01-11)
==================

* Initial public release - [@agileanimal](https://github.com/agileanimal).

