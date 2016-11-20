require 'spec_helper'
require 'ostruct'

describe Grape::Entity do
  let(:fresh_class) { Class.new(Grape::Entity) }

  context 'class methods' do
    subject { fresh_class }

    describe '.expose' do
      context 'multiple attributes' do
        it 'is able to add multiple exposed attributes with a single call' do
          subject.expose :name, :email, :location
          expect(subject.root_exposures.size).to eq 3
        end

        it 'sets the same options for all.root_exposures passed' do
          subject.expose :name, :email, :location, documentation: true
          subject.root_exposures.each { |v| expect(v.documentation).to eq true }
        end
      end

      context 'option validation' do
        it 'makes sure that :as only works on single attribute calls' do
          expect { subject.expose :name, :email, as: :foo }.to raise_error ArgumentError
          expect { subject.expose :name, as: :foo }.not_to raise_error
        end

        it 'makes sure that :format_with as a proc cannot be used with a block' do
          expect { subject.expose :name, format_with: proc {} {} }.to raise_error ArgumentError
        end

        it 'makes sure unknown options are not silently ignored' do
          expect { subject.expose :name, unknown: nil }.to raise_error ArgumentError
        end
      end

      context 'with a :merge option' do
        let(:nested_hash) do
          { something: { like_nested_hash: true }, special: { like_nested_hash: '12' } }
        end

        it 'merges an exposure to the root' do
          subject.expose(:something, merge: true)
          expect(subject.represent(nested_hash).serializable_hash).to eq(nested_hash[:something])
        end

        it 'allows to solve collisions providing a lambda to a :merge option' do
          subject.expose(:something, merge: true)
          subject.expose(:special, merge: ->(_, v1, v2) { v1 && v2 ? 'brand new val' : v2 })
          expect(subject.represent(nested_hash).serializable_hash).to eq(like_nested_hash: 'brand new val')
        end

        context 'and nested object is nil' do
          let(:nested_hash) do
            { something: nil, special: { like_nested_hash: '12' } }
          end

          it 'adds nothing to output' do
            subject.expose(:something, merge: true)
            subject.expose(:special)
            expect(subject.represent(nested_hash).serializable_hash).to eq(special: { like_nested_hash: '12' })
          end
        end
      end

      context 'with a block' do
        it 'errors out if called with multiple attributes' do
          expect { subject.expose(:name, :email) { true } }.to raise_error ArgumentError
        end

        it 'references an instance of the entity with :using option' do
          module EntitySpec
            class SomeObject1
              attr_accessor :prop1

              def initialize
                @prop1 = 'value1'
              end
            end

            class BogusEntity < Grape::Entity
              expose :prop1
            end
          end

          subject.expose(:bogus, using: EntitySpec::BogusEntity) do |entity|
            entity.prop1 = 'MODIFIED 2'
            entity
          end

          object = EntitySpec::SomeObject1.new
          value = subject.represent(object).value_for(:bogus)
          expect(value).to be_instance_of EntitySpec::BogusEntity

          prop1 = value.value_for(:prop1)
          expect(prop1).to eq 'MODIFIED 2'
        end

        context 'with parameters passed to the block' do
          it 'sets the :proc option in the exposure options' do
            block = ->(_) { true }
            subject.expose :name, using: 'Awesome', &block
            exposure = subject.find_exposure(:name)
            expect(exposure.subexposure.block).to eq(block)
            expect(exposure.using_class_name).to eq('Awesome')
          end

          it 'references an instance of the entity without any options' do
            subject.expose(:size) { |_| self }
            expect(subject.represent({}).value_for(:size)).to be_an_instance_of fresh_class
          end
        end

        context 'with no parameters passed to the block' do
          it 'adds a nested exposure' do
            subject.expose :awesome do
              subject.expose :nested do
                subject.expose :moar_nested, as: 'weee'
              end
              subject.expose :another_nested, using: 'Awesome'
            end

            awesome = subject.find_exposure(:awesome)
            nested = awesome.find_nested_exposure(:nested)
            another_nested = awesome.find_nested_exposure(:another_nested)
            moar_nested = nested.find_nested_exposure(:moar_nested)

            expect(awesome).to be_nesting
            expect(nested).to_not be_nil
            expect(another_nested).to_not be_nil
            expect(another_nested.using_class_name).to eq('Awesome')
            expect(moar_nested).to_not be_nil
            expect(moar_nested.key).to eq(:weee)
          end

          it 'represents the exposure as a hash of its nested.root_exposures' do
            subject.expose :awesome do
              subject.expose(:nested) { |_| 'value' }
              subject.expose(:another_nested) { |_| 'value' }
            end

            expect(subject.represent({}).value_for(:awesome)).to eq(
              nested: 'value',
              another_nested: 'value'
            )
          end

          it 'does not represent nested.root_exposures whose conditions are not met' do
            subject.expose :awesome do
              subject.expose(:condition_met, if: ->(_, _) { true }) { |_| 'value' }
              subject.expose(:condition_not_met, if: ->(_, _) { false }) { |_| 'value' }
            end

            expect(subject.represent({}).value_for(:awesome)).to eq(condition_met: 'value')
          end

          it 'does not represent attributes, declared inside nested exposure, outside of it' do
            subject.expose :awesome do
              subject.expose(:nested) { |_| 'value' }
              subject.expose(:another_nested) { |_| 'value' }
              subject.expose :second_level_nested do
                subject.expose(:deeply_exposed_attr) { |_| 'value' }
              end
            end

            expect(subject.represent({}).serializable_hash).to eq(
              awesome: {
                nested: 'value',
                another_nested: 'value',
                second_level_nested: {
                  deeply_exposed_attr: 'value'
                }
              }
            )
          end

          it 'merges complex nested attributes' do
            class ClassRoom < Grape::Entity
              expose(:parents, using: 'Parent') { |_| [{}, {}] }
            end

            class Person < Grape::Entity
              expose :user do
                expose(:in_first) { |_| 'value' }
              end
            end

            class Student < Person
              expose :user do
                expose(:user_id) { |_| 'value' }
                expose(:user_display_id, as: :display_id) { |_| 'value' }
              end
            end

            class Parent < Person
              expose(:children, using: 'Student') { |_| [{}, {}] }
            end

            expect(ClassRoom.represent({}).serializable_hash).to eq(
              parents: [
                {
                  user: { in_first: 'value' },
                  children: [
                    { user: { in_first: 'value', user_id: 'value', display_id: 'value' } },
                    { user: { in_first: 'value', user_id: 'value', display_id: 'value' } }
                  ]
                },
                {
                  user: { in_first: 'value' },
                  children: [
                    { user: { in_first: 'value', user_id: 'value', display_id: 'value' } },
                    { user: { in_first: 'value', user_id: 'value', display_id: 'value' } }
                  ]
                }
              ]
            )
          end

          it 'merges results of deeply nested double.root_exposures inside of nesting exposure' do
            entity = Class.new(Grape::Entity) do
              expose :data do
                expose :something do
                  expose(:x) { |_| 'x' }
                end
                expose :something do
                  expose(:y) { |_| 'y' }
                end
              end
            end
            expect(entity.represent({}).serializable_hash).to eq(
              data: {
                something: {
                  x: 'x',
                  y: 'y'
                }
              }
            )
          end

          it 'serializes deeply nested presenter exposures' do
            e = Class.new(Grape::Entity) do
              expose :f
            end
            subject.expose :a do
              subject.expose :b do
                subject.expose :c do
                  subject.expose :lol, using: e
                end
              end
            end
            expect(subject.represent(lol: { f: 123 }).serializable_hash).to eq(
              a: { b: { c: { lol: { f: 123 } } } }
            )
          end

          it 'is safe if its nested.root_exposures are safe' do
            subject.with_options safe: true do
              subject.expose :awesome do
                subject.expose(:nested) { |_| 'value' }
              end
              subject.expose :not_awesome do
                subject.expose :nested
              end
            end
            expect(subject.represent({}, serializable: true)).to eq(
              awesome: {
                nested: 'value'
              },
              not_awesome: {
                nested: nil
              }
            )
          end
          it 'merges attriutes if :merge option is passed' do
            user_entity = Class.new(Grape::Entity)
            admin_entity = Class.new(Grape::Entity)
            user_entity.expose(:id, :name)
            admin_entity.expose(:id, :name)

            subject.expose(:profiles) do
              subject.expose(:users, merge: true, using: user_entity)
              subject.expose(:admins, merge: true, using: admin_entity)
            end

            subject.expose :awesome do
              subject.expose(:nested, merge: true) { |_| { just_a_key: 'value' } }
              subject.expose(:another_nested, merge: true) { |_| { just_another_key: 'value' } }
            end

            additional_hash = { users: [{ id: 1, name: 'John' }, { id: 2, name: 'Jay' }],
                                admins: [{ id: 3, name: 'Jack' }, { id: 4, name: 'James' }] }
            expect(subject.represent(additional_hash).serializable_hash).to eq(
              profiles: additional_hash[:users] + additional_hash[:admins],
              awesome: { just_a_key: 'value', just_another_key: 'value' }
            )
          end
        end
      end

      context 'inherited.root_exposures' do
        it 'returns.root_exposures from an ancestor' do
          subject.expose :name, :email
          child_class = Class.new(subject)

          expect(child_class.root_exposures).to eq(subject.root_exposures)
        end

        it 'returns.root_exposures from multiple ancestor' do
          subject.expose :name, :email
          parent_class = Class.new(subject)
          child_class  = Class.new(parent_class)

          expect(child_class.root_exposures).to eq(subject.root_exposures)
        end

        it 'returns descendant.root_exposures as a priority' do
          subject.expose :name, :email
          child_class = Class.new(subject)
          child_class.expose :name do |_|
            'foo'
          end

          expect(subject.represent({ name: 'bar' }, serializable: true)).to eq(email: nil, name: 'bar')
          expect(child_class.represent({ name: 'bar' }, serializable: true)).to eq(email: nil, name: 'foo')
        end
      end

      context 'register formatters' do
        let(:date_formatter) { ->(date) { date.strftime('%m/%d/%Y') } }

        it 'registers a formatter' do
          subject.format_with :timestamp, &date_formatter

          expect(subject.formatters[:timestamp]).not_to be_nil
        end

        it 'inherits formatters from ancestors' do
          subject.format_with :timestamp, &date_formatter
          child_class = Class.new(subject)

          expect(child_class.formatters).to eq subject.formatters
        end

        it 'does not allow registering a formatter without a block' do
          expect { subject.format_with :foo }.to raise_error ArgumentError
        end

        it 'formats an exposure with a registered formatter' do
          subject.format_with :timestamp do |date|
            date.strftime('%m/%d/%Y')
          end

          subject.expose :birthday, format_with: :timestamp

          model = { birthday: Time.gm(2012, 2, 27) }
          expect(subject.new(double(model)).as_json[:birthday]).to eq '02/27/2012'
        end

        it 'formats an exposure with a :format_with lambda that returns a value from the entity instance' do
          object = {}

          subject.expose(:size, format_with: ->(_value) { object.class.to_s })
          expect(subject.represent(object).value_for(:size)).to eq object.class.to_s
        end

        it 'formats an exposure with a :format_with symbol that returns a value from the entity instance' do
          subject.format_with :size_formatter do |_date|
            object.class.to_s
          end

          object = {}

          subject.expose(:size, format_with: :size_formatter)
          expect(subject.represent(object).value_for(:size)).to eq object.class.to_s
        end

        it 'works global on Grape::Entity' do
          Grape::Entity.format_with :size_formatter do |_date|
            object.class.to_s
          end
          object = {}

          subject.expose(:size, format_with: :size_formatter)
          expect(subject.represent(object).value_for(:size)).to eq object.class.to_s
        end
      end

      it 'works global on Grape::Entity' do
        Grape::Entity.expose :a
        object = { a: 11, b: 22 }
        expect(Grape::Entity.represent(object).value_for(:a)).to eq 11
        subject.expose :b
        expect(subject.represent(object).value_for(:a)).to eq 11
        expect(subject.represent(object).value_for(:b)).to eq 22
        Grape::Entity.unexpose :a
      end
    end

    describe '.unexpose' do
      it 'is able to remove exposed attributes' do
        subject.expose :name, :email
        subject.unexpose :email

        expect(subject.root_exposures.length).to eq 1
        expect(subject.root_exposures[0].attribute).to eq :name
      end

      context 'inherited.root_exposures' do
        it 'when called from child class, only removes from the attribute from child' do
          subject.expose :name, :email
          child_class = Class.new(subject)
          child_class.unexpose :email

          expect(child_class.root_exposures.length).to eq 1
          expect(child_class.root_exposures[0].attribute).to eq :name
          expect(subject.root_exposures[0].attribute).to eq :name
          expect(subject.root_exposures[1].attribute).to eq :email
        end

        context 'when called from the parent class' do
          it 'remove from parent and do not remove from child classes' do
            subject.expose :name, :email
            child_class = Class.new(subject)
            subject.unexpose :email

            expect(subject.root_exposures.length).to eq 1
            expect(subject.root_exposures[0].attribute).to eq :name
            expect(child_class.root_exposures[0].attribute).to eq :name
            expect(child_class.root_exposures[1].attribute).to eq :email
          end
        end
      end

      it 'does not allow unexposing inside of nesting exposures' do
        expect do
          Class.new(Grape::Entity) do
            expose :something do
              expose :x
              unexpose :x
            end
          end
        end.to raise_error(/You cannot call 'unexpose`/)
      end

      it 'works global on Grape::Entity' do
        Grape::Entity.expose :x
        expect(Grape::Entity.root_exposures[0].attribute).to eq(:x)
        Grape::Entity.unexpose :x
        expect(Grape::Entity.root_exposures).to eq([])
      end
    end

    describe '.with_options' do
      it 'raises an error for unknown options' do
        block = proc do
          with_options(unknown: true) do
            expose :awesome_thing
          end
        end

        expect { subject.class_eval(&block) }.to raise_error ArgumentError
      end

      it 'applies the options to all.root_exposures inside' do
        subject.class_eval do
          with_options(if: { awesome: true }) do
            expose :awesome_thing, using: 'Awesome'
          end
        end

        exposure = subject.find_exposure(:awesome_thing)
        expect(exposure.using_class_name).to eq('Awesome')
        expect(exposure.conditions[0].cond_hash).to eq(awesome: true)
      end

      it 'allows for nested .with_options' do
        subject.class_eval do
          with_options(if: { awesome: true }) do
            with_options(using: 'Something') do
              expose :awesome_thing
            end
          end
        end

        exposure = subject.find_exposure(:awesome_thing)
        expect(exposure.using_class_name).to eq('Something')
        expect(exposure.conditions[0].cond_hash).to eq(awesome: true)
      end

      it 'overrides nested :as option' do
        subject.class_eval do
          with_options(as: :sweet) do
            expose :awesome_thing, as: :extra_smooth
          end
        end

        exposure = subject.find_exposure(:awesome_thing)
        expect(exposure.key).to eq :extra_smooth
      end

      it 'merges nested :if option' do
        match_proc = ->(_obj, _opts) { true }

        subject.class_eval do
          # Symbol
          with_options(if: :awesome) do
            # Hash
            with_options(if: { awesome: true }) do
              # Proc
              with_options(if: match_proc) do
                # Hash (override existing key and merge new key)
                with_options(if: { awesome: false, less_awesome: true }) do
                  expose :awesome_thing
                end
              end
            end
          end
        end

        exposure = subject.find_exposure(:awesome_thing)
        expect(exposure.conditions.any?(&:inversed?)).to be_falsey
        expect(exposure.conditions[0].symbol).to eq(:awesome)
        expect(exposure.conditions[1].block).to eq(match_proc)
        expect(exposure.conditions[2].cond_hash).to eq(awesome: false, less_awesome: true)
      end

      it 'merges nested :unless option' do
        match_proc = ->(_, _) { true }

        subject.class_eval do
          # Symbol
          with_options(unless: :awesome) do
            # Hash
            with_options(unless: { awesome: true }) do
              # Proc
              with_options(unless: match_proc) do
                # Hash (override existing key and merge new key)
                with_options(unless: { awesome: false, less_awesome: true }) do
                  expose :awesome_thing
                end
              end
            end
          end
        end

        exposure = subject.find_exposure(:awesome_thing)
        expect(exposure.conditions.all?(&:inversed?)).to be_truthy
        expect(exposure.conditions[0].symbol).to eq(:awesome)
        expect(exposure.conditions[1].block).to eq(match_proc)
        expect(exposure.conditions[2].cond_hash).to eq(awesome: false, less_awesome: true)
      end

      it 'overrides nested :using option' do
        subject.class_eval do
          with_options(using: 'Something') do
            expose :awesome_thing, using: 'SomethingElse'
          end
        end

        exposure = subject.find_exposure(:awesome_thing)
        expect(exposure.using_class_name).to eq('SomethingElse')
      end

      it 'aliases :with option to :using option' do
        subject.class_eval do
          with_options(using: 'Something') do
            expose :awesome_thing, with: 'SomethingElse'
          end
        end

        exposure = subject.find_exposure(:awesome_thing)
        expect(exposure.using_class_name).to eq('SomethingElse')
      end

      it 'overrides nested :proc option' do
        match_proc = ->(_obj, _opts) { 'more awesomer' }

        subject.class_eval do
          with_options(proc: ->(_obj, _opts) { 'awesome' }) do
            expose :awesome_thing, proc: match_proc
          end
        end

        exposure = subject.find_exposure(:awesome_thing)
        expect(exposure.block).to eq(match_proc)
      end

      it 'overrides nested :documentation option' do
        subject.class_eval do
          with_options(documentation: { desc: 'Description.' }) do
            expose :awesome_thing, documentation: { desc: 'Other description.' }
          end
        end

        exposure = subject.find_exposure(:awesome_thing)
        expect(exposure.documentation).to eq(desc: 'Other description.')
      end
    end

    describe '.represent' do
      it 'returns a single entity if called with one object' do
        expect(subject.represent(Object.new)).to be_kind_of(subject)
      end

      it 'returns a single entity if called with a hash' do
        expect(subject.represent({})).to be_kind_of(subject)
      end

      it 'returns multiple entities if called with a collection' do
        representation = subject.represent(Array.new(4) { Object.new })
        expect(representation).to be_kind_of Array
        expect(representation.size).to eq(4)
        expect(representation.reject { |r| r.is_a?(subject) }).to be_empty
      end

      it 'adds the collection: true option if called with a collection' do
        representation = subject.represent(Array.new(4) { Object.new })
        representation.each { |r| expect(r.options[:collection]).to be true }
      end

      it 'returns a serialized hash of a single object if serializable: true' do
        subject.expose(:awesome) { |_| true }
        representation = subject.represent(Object.new, serializable: true)
        expect(representation).to eq(awesome: true)
      end

      it 'returns a serialized array of hashes of multiple objects if serializable: true' do
        subject.expose(:awesome) { |_| true }
        representation = subject.represent(Array.new(2) { Object.new }, serializable: true)
        expect(representation).to eq([{ awesome: true }, { awesome: true }])
      end

      it 'returns a serialized hash of a hash' do
        subject.expose(:awesome)
        representation = subject.represent({ awesome: true }, serializable: true)
        expect(representation).to eq(awesome: true)
      end

      it 'returns a serialized hash of an OpenStruct' do
        subject.expose(:awesome)
        representation = subject.represent(OpenStruct.new, serializable: true)
        expect(representation).to eq(awesome: nil)
      end

      it 'raises error if field not found' do
        subject.expose(:awesome)
        expect do
          subject.represent(Object.new, serializable: true)
        end.to raise_error(NoMethodError, /missing attribute `awesome'/)
      end

      context 'with specified fields' do
        it 'returns only specified fields with only option' do
          subject.expose(:id, :name, :phone)
          representation = subject.represent(OpenStruct.new, only: [:id, :name], serializable: true)
          expect(representation).to eq(id: nil, name: nil)
        end

        it 'returns all fields except the ones specified in the except option' do
          subject.expose(:id, :name, :phone)
          representation = subject.represent(OpenStruct.new, except: [:phone], serializable: true)
          expect(representation).to eq(id: nil, name: nil)
        end

        it 'returns only fields specified in the only option and not specified in the except option' do
          subject.expose(:id, :name, :phone)
          representation = subject.represent(OpenStruct.new,
                                             only: [:name, :phone],
                                             except: [:phone], serializable: true)
          expect(representation).to eq(name: nil)
        end

        context 'with strings or symbols passed to only and except' do
          let(:object) { OpenStruct.new(user: {}) }

          before do
            user_entity = Class.new(Grape::Entity)
            user_entity.expose(:id, :name, :email)

            subject.expose(:id, :name, :phone, :address)
            subject.expose(:user, using: user_entity)
          end

          it 'can specify "only" option attributes as strings' do
            representation = subject.represent(object, only: ['id', 'name', { 'user' => ['email'] }], serializable: true)
            expect(representation).to eq(id: nil, name: nil, user: { email: nil })
          end

          it 'can specify "except" option attributes as strings' do
            representation = subject.represent(object, except: ['id', 'name', { 'user' => ['email'] }], serializable: true)
            expect(representation).to eq(phone: nil, address: nil, user: { id: nil, name: nil })
          end

          it 'can specify "only" option attributes as symbols' do
            representation = subject.represent(object, only: [:name, :phone, { user: [:name] }], serializable: true)
            expect(representation).to eq(name: nil, phone: nil, user: { name: nil })
          end

          it 'can specify "except" option attributes as symbols' do
            representation = subject.represent(object, except: [:name, :phone, { user: [:name] }], serializable: true)
            expect(representation).to eq(id: nil, address: nil, user: { id: nil, email: nil })
          end

          it 'can specify "only" attributes as strings and symbols' do
            representation = subject.represent(object, only: [:id, 'address', { user: [:id, 'name'] }], serializable: true)
            expect(representation).to eq(id: nil, address: nil, user: { id: nil, name: nil })
          end

          it 'can specify "except" attributes as strings and symbols' do
            representation = subject.represent(object, except: [:id, 'address', { user: [:id, 'name'] }], serializable: true)
            expect(representation).to eq(name: nil, phone: nil, user: { email: nil })
          end

          context 'with nested attributes' do
            before do
              subject.expose :additional do
                subject.expose :something
              end
            end

            it 'preserves nesting' do
              expect(subject.represent({ something: 123 }, only: [{ additional: [:something] }], serializable: true)).to eq(
                additional: {
                  something: 123
                }
              )
            end
          end
        end

        it 'can specify children attributes with only' do
          user_entity = Class.new(Grape::Entity)
          user_entity.expose(:id, :name, :email)

          subject.expose(:id, :name, :phone)
          subject.expose(:user, using: user_entity)

          representation = subject.represent(OpenStruct.new(user: {}), only: [:id, :name, { user: [:name, :email] }], serializable: true)
          expect(representation).to eq(id: nil, name: nil, user: { name: nil, email: nil })
        end

        it 'can specify children attributes with except' do
          user_entity = Class.new(Grape::Entity)
          user_entity.expose(:id, :name, :email)

          subject.expose(:id, :name, :phone)
          subject.expose(:user, using: user_entity)

          representation = subject.represent(OpenStruct.new(user: {}), except: [:phone, { user: [:id] }], serializable: true)
          expect(representation).to eq(id: nil, name: nil, user: { name: nil, email: nil })
        end

        it 'can specify children attributes with mixed only and except' do
          user_entity = Class.new(Grape::Entity)
          user_entity.expose(:id, :name, :email, :address)

          subject.expose(:id, :name, :phone, :mobile_phone)
          subject.expose(:user, using: user_entity)

          representation = subject.represent(OpenStruct.new(user: {}),
                                             only: [:id, :name, :phone, user: [:id, :name, :email]],
                                             except: [:phone, { user: [:id] }], serializable: true)
          expect(representation).to eq(id: nil, name: nil, user: { name: nil, email: nil })
        end

        context 'specify attribute with exposure condition' do
          it 'returns only specified fields' do
            subject.expose(:id)
            subject.with_options(if: { condition: true }) do
              subject.expose(:name)
            end

            representation = subject.represent(OpenStruct.new, condition: true, only: [:id, :name], serializable: true)
            expect(representation).to eq(id: nil, name: nil)
          end

          it 'does not return fields specified in the except option' do
            subject.expose(:id, :phone)
            subject.with_options(if: { condition: true }) do
              subject.expose(:name, :mobile_phone)
            end

            representation = subject.represent(OpenStruct.new, condition: true, except: [:phone, :mobile_phone], serializable: true)
            expect(representation).to eq(id: nil, name: nil)
          end

          it 'choses proper exposure according to condition' do
            strategy1 = ->(_obj, _opts) { 'foo' }
            strategy2 = ->(_obj, _opts) { 'bar' }

            subject.expose :id, proc: strategy1
            subject.expose :id, proc: strategy2
            expect(subject.represent({}, condition: false, serializable: true)).to eq(id: 'bar')
            expect(subject.represent({}, condition: true, serializable: true)).to eq(id: 'bar')

            subject.unexpose_all

            subject.expose :id, proc: strategy1, if: :condition
            subject.expose :id, proc: strategy2
            expect(subject.represent({}, condition: false, serializable: true)).to eq(id: 'bar')
            expect(subject.represent({}, condition: true, serializable: true)).to eq(id: 'bar')

            subject.unexpose_all

            subject.expose :id, proc: strategy1
            subject.expose :id, proc: strategy2, if: :condition
            expect(subject.represent({}, condition: false, serializable: true)).to eq(id: 'foo')
            expect(subject.represent({}, condition: true, serializable: true)).to eq(id: 'bar')

            subject.unexpose_all

            subject.expose :id, proc: strategy1, if: :condition1
            subject.expose :id, proc: strategy2, if: :condition2
            expect(subject.represent({}, condition1: false, condition2: false, serializable: true)).to eq({})
            expect(subject.represent({}, condition1: false, condition2: true, serializable: true)).to eq(id: 'bar')
            expect(subject.represent({}, condition1: true, condition2: false, serializable: true)).to eq(id: 'foo')
            expect(subject.represent({}, condition1: true, condition2: true, serializable: true)).to eq(id: 'bar')
          end

          it 'does not merge nested exposures with plain hashes' do
            subject.expose(:id)
            subject.expose(:info, if: :condition1) do
              subject.expose :a, :b
              subject.expose(:additional, if: :condition2) do |_obj, _opts|
                {
                  x: 11, y: 22, c: 123
                }
              end
            end
            subject.expose(:info, if: :condition2) do
              subject.expose(:additional) do
                subject.expose :c
              end
            end
            subject.expose(:d, as: :info, if: :condition3)

            obj = { id: 123, a: 1, b: 2, c: 3, d: 4 }

            expect(subject.represent(obj, serializable: true)).to eq(id: 123)
            expect(subject.represent(obj, condition1: true, serializable: true)).to eq(id: 123, info: { a: 1, b: 2 })
            expect(subject.represent(obj, condition2: true, serializable: true)).to eq(
              id: 123,
              info: {
                additional: {
                  c: 3
                }
              }
            )
            expect(subject.represent(obj, condition1: true, condition2: true, serializable: true)).to eq(
              id: 123,
              info: {
                a: 1, b: 2, additional: { c: 3 }
              }
            )
            expect(subject.represent(obj, condition3: true, serializable: true)).to eq(id: 123, info: 4)
            expect(subject.represent(obj, condition1: true, condition2: true, condition3: true, serializable: true)).to eq(id: 123, info: 4)
          end
        end

        context 'attribute with alias' do
          it 'returns only specified fields' do
            subject.expose(:id)
            subject.expose(:name, as: :title)

            representation = subject.represent(OpenStruct.new, condition: true, only: [:id, :title], serializable: true)
            expect(representation).to eq(id: nil, title: nil)
          end

          it 'does not return fields specified in the except option' do
            subject.expose(:id)
            subject.expose(:name, as: :title)
            subject.expose(:phone, as: :phone_number)

            representation = subject.represent(OpenStruct.new, condition: true, except: [:phone_number], serializable: true)
            expect(representation).to eq(id: nil, title: nil)
          end
        end

        context 'attribute that is an entity itself' do
          it 'returns correctly the children entity attributes' do
            user_entity = Class.new(Grape::Entity)
            user_entity.expose(:id, :name, :email)

            nephew_entity = Class.new(Grape::Entity)
            nephew_entity.expose(:id, :name, :email)

            subject.expose(:id, :name, :phone)
            subject.expose(:user, using: user_entity)
            subject.expose(:nephew, using: nephew_entity)

            representation = subject.represent(OpenStruct.new(user: {}),
                                               only: [:id, :name, :user], except: [:nephew], serializable: true)
            expect(representation).to eq(id: nil, name: nil, user: { id: nil, name: nil, email: nil })
          end
        end
      end
    end

    describe '.present_collection' do
      it 'make the objects accessible' do
        subject.present_collection true
        subject.expose :items

        representation = subject.represent(Array.new(4) { Object.new })
        expect(representation).to be_kind_of(subject)
        expect(representation.object).to be_kind_of(Hash)
        expect(representation.object).to have_key :items
        expect(representation.object[:items]).to be_kind_of Array
        expect(representation.object[:items].size).to be 4
      end

      it 'serializes items with my root name' do
        subject.present_collection true, :my_items
        subject.expose :my_items

        representation = subject.represent(Array.new(4) { Object.new }, serializable: true)
        expect(representation).to be_kind_of(Grape::Entity::Exposure::NestingExposure::OutputBuilder)
        expect(representation).to be_kind_of(Hash)
        expect(representation).to have_key :my_items
        expect(representation[:my_items]).to be_kind_of Array
        expect(representation[:my_items].size).to be 4
      end
    end

    describe '.root' do
      context 'with singular and plural root keys' do
        before(:each) do
          subject.root 'things', 'thing'
        end

        context 'with a single object' do
          it 'allows a root element name to be specified' do
            representation = subject.represent(Object.new)
            expect(representation).to be_kind_of Hash
            expect(representation).to have_key 'thing'
            expect(representation['thing']).to be_kind_of(subject)
          end
        end

        context 'with an array of objects' do
          it 'allows a root element name to be specified' do
            representation = subject.represent(Array.new(4) { Object.new })
            expect(representation).to be_kind_of Hash
            expect(representation).to have_key 'things'
            expect(representation['things']).to be_kind_of Array
            expect(representation['things'].size).to eq 4
            expect(representation['things'].reject { |r| r.is_a?(subject) }).to be_empty
          end
        end

        context 'it can be overridden' do
          it 'can be disabled' do
            representation = subject.represent(Array.new(4) { Object.new }, root: false)
            expect(representation).to be_kind_of Array
            expect(representation.size).to eq 4
            expect(representation.reject { |r| r.is_a?(subject) }).to be_empty
          end
          it 'can use a different name' do
            representation = subject.represent(Array.new(4) { Object.new }, root: 'others')
            expect(representation).to be_kind_of Hash
            expect(representation).to have_key 'others'
            expect(representation['others']).to be_kind_of Array
            expect(representation['others'].size).to eq 4
            expect(representation['others'].reject { |r| r.is_a?(subject) }).to be_empty
          end
        end
      end

      context 'with singular root key' do
        before(:each) do
          subject.root nil, 'thing'
        end

        context 'with a single object' do
          it 'allows a root element name to be specified' do
            representation = subject.represent(Object.new)
            expect(representation).to be_kind_of Hash
            expect(representation).to have_key 'thing'
            expect(representation['thing']).to be_kind_of(subject)
          end
        end

        context 'with an array of objects' do
          it 'allows a root element name to be specified' do
            representation = subject.represent(Array.new(4) { Object.new })
            expect(representation).to be_kind_of Array
            expect(representation.size).to eq 4
            expect(representation.reject { |r| r.is_a?(subject) }).to be_empty
          end
        end
      end

      context 'with plural root key' do
        before(:each) do
          subject.root 'things'
        end

        context 'with a single object' do
          it 'allows a root element name to be specified' do
            expect(subject.represent(Object.new)).to be_kind_of(subject)
          end
        end

        context 'with an array of objects' do
          it 'allows a root element name to be specified' do
            representation = subject.represent(Array.new(4) { Object.new })
            expect(representation).to be_kind_of Hash
            expect(representation).to have_key('things')
            expect(representation['things']).to be_kind_of Array
            expect(representation['things'].size).to eq 4
            expect(representation['things'].reject { |r| r.is_a?(subject) }).to be_empty
          end
        end
      end

      context 'inheriting from parent entity' do
        before(:each) do
          subject.root 'things', 'thing'
        end

        it 'inherits single root' do
          child_class = Class.new(subject)
          representation = child_class.represent(Object.new)
          expect(representation).to be_kind_of Hash
          expect(representation).to have_key 'thing'
          expect(representation['thing']).to be_kind_of(child_class)
        end

        it 'inherits array root root' do
          child_class = Class.new(subject)
          representation = child_class.represent(Array.new(4) { Object.new })
          expect(representation).to be_kind_of Hash
          expect(representation).to have_key('things')
          expect(representation['things']).to be_kind_of Array
          expect(representation['things'].size).to eq 4
          expect(representation['things'].reject { |r| r.is_a?(child_class) }).to be_empty
        end
      end
    end

    describe '#initialize' do
      it 'takes an object and an optional options hash' do
        expect { subject.new(Object.new) }.not_to raise_error
        expect { subject.new }.to raise_error ArgumentError
        expect { subject.new(Object.new, {}) }.not_to raise_error
      end

      it 'has attribute readers for the object and options' do
        entity = subject.new('abc', {})
        expect(entity.object).to eq 'abc'
        expect(entity.options).to eq({})
      end
    end
  end

  context 'instance methods' do
    let(:model) { double(attributes) }

    let(:attributes) do
      {
        name: 'Bob Bobson',
        email: 'bob@example.com',
        birthday: Time.gm(2012, 2, 27),
        fantasies: ['Unicorns', 'Double Rainbows', 'Nessy'],
        characteristics: [
          { key: 'hair_color', value: 'brown' }
        ],
        friends: [
          double(name: 'Friend 1', email: 'friend1@example.com', characteristics: [], fantasies: [], birthday: Time.gm(2012, 2, 27), friends: []),
          double(name: 'Friend 2', email: 'friend2@example.com', characteristics: [], fantasies: [], birthday: Time.gm(2012, 2, 27), friends: [])
        ],
        extra: { key: 'foo', value: 'bar' },
        nested: [
          { name: 'n1', data: { key: 'ex1', value: 'v1' } },
          { name: 'n2', data: { key: 'ex2', value: 'v2' } }
        ]
      }
    end

    subject { fresh_class.new(model) }

    describe '#serializable_hash' do
      it 'does not throw an exception if a nil options object is passed' do
        expect { fresh_class.new(model).serializable_hash(nil) }.not_to raise_error
      end

      it 'does not blow up when the model is nil' do
        fresh_class.expose :name
        expect { fresh_class.new(nil).serializable_hash }.not_to raise_error
      end

      context 'with safe option' do
        it 'does not throw an exception when an attribute is not found on the object' do
          fresh_class.expose :name, :nonexistent_attribute, safe: true
          expect { fresh_class.new(model).serializable_hash }.not_to raise_error
        end

        it 'exposes values of private method calls' do
          some_class = Class.new do
            define_method :name do
              true
            end
            private :name
          end
          fresh_class.expose :name, safe: true
          expect(fresh_class.new(some_class.new).serializable_hash).to eq(name: true)
        end

        it "does expose attributes that don't exist on the object" do
          fresh_class.expose :email, :nonexistent_attribute, :name, safe: true

          res = fresh_class.new(model).serializable_hash
          expect(res).to have_key :email
          expect(res).to have_key :nonexistent_attribute
          expect(res).to have_key :name
        end

        it "does expose attributes that don't exist on the object as nil" do
          fresh_class.expose :email, :nonexistent_attribute, :name, safe: true

          res = fresh_class.new(model).serializable_hash
          expect(res[:nonexistent_attribute]).to eq(nil)
        end

        it 'does expose attributes marked as safe if model is a hash object' do
          fresh_class.expose :name, safe: true

          res = fresh_class.new(name: 'myname').serializable_hash
          expect(res).to have_key :name
        end

        it "does expose attributes that don't exist on the object as nil if criteria is true" do
          fresh_class.expose :email
          fresh_class.expose :nonexistent_attribute, safe: true, if: ->(_obj, _opts) { false }
          fresh_class.expose :nonexistent_attribute2, safe: true, if: ->(_obj, _opts) { true }

          res = fresh_class.new(model).serializable_hash
          expect(res).to have_key :email
          expect(res).not_to have_key :nonexistent_attribute
          expect(res).to have_key :nonexistent_attribute2
        end
      end

      context 'without safe option' do
        it 'throws an exception when an attribute is not found on the object' do
          fresh_class.expose :name, :nonexistent_attribute
          expect { fresh_class.new(model).serializable_hash }.to raise_error NoMethodError
        end

        it "exposes attributes that don't exist on the object only when they are generated by a block" do
          fresh_class.expose :nonexistent_attribute do |_model, _opts|
            'well, I do exist after all'
          end
          res = fresh_class.new(model).serializable_hash
          expect(res).to have_key :nonexistent_attribute
        end

        it 'does not expose attributes that are generated by a block but have not passed criteria' do
          fresh_class.expose :nonexistent_attribute,
                             proc: ->(_model, _opts) { 'I exist, but it is not yet my time to shine' },
                             if: ->(_model, _opts) { false }
          res = fresh_class.new(model).serializable_hash
          expect(res).not_to have_key :nonexistent_attribute
        end
      end

      it "exposes attributes that don't exist on the object only when they are generated by a block with options" do
        module EntitySpec
          class TestEntity < Grape::Entity
          end
        end

        fresh_class.expose :nonexistent_attribute, using: EntitySpec::TestEntity do |_model, _opts|
          'well, I do exist after all'
        end
        res = fresh_class.new(model).serializable_hash
        expect(res).to have_key :nonexistent_attribute
      end

      it 'does not expose attributes that are generated by a block but have not passed criteria' do
        fresh_class.expose :nonexistent_attribute,
                           proc: ->(_, _) { 'I exist, but it is not yet my time to shine' },
                           if: ->(_, _) { false }
        res = fresh_class.new(model).serializable_hash
        expect(res).not_to have_key :nonexistent_attribute
      end

      context '#serializable_hash' do
        module EntitySpec
          class EmbeddedExample
            def serializable_hash(_opts = {})
              { abc: 'def' }
            end
          end

          class EmbeddedExampleWithHash
            def name
              'abc'
            end

            def embedded
              { a: nil, b: EmbeddedExample.new }
            end
          end

          class EmbeddedExampleWithMany
            def name
              'abc'
            end

            def embedded
              [EmbeddedExample.new, EmbeddedExample.new]
            end
          end

          class EmbeddedExampleWithOne
            def name
              'abc'
            end

            def embedded
              EmbeddedExample.new
            end
          end
        end

        it 'serializes embedded objects which respond to #serializable_hash' do
          fresh_class.expose :name, :embedded
          presenter = fresh_class.new(EntitySpec::EmbeddedExampleWithOne.new)
          expect(presenter.serializable_hash).to eq(name: 'abc', embedded: { abc: 'def' })
        end

        it 'serializes embedded arrays of objects which respond to #serializable_hash' do
          fresh_class.expose :name, :embedded
          presenter = fresh_class.new(EntitySpec::EmbeddedExampleWithMany.new)
          expect(presenter.serializable_hash).to eq(name: 'abc', embedded: [{ abc: 'def' }, { abc: 'def' }])
        end

        it 'serializes embedded hashes of objects which respond to #serializable_hash' do
          fresh_class.expose :name, :embedded
          presenter = fresh_class.new(EntitySpec::EmbeddedExampleWithHash.new)
          expect(presenter.serializable_hash).to eq(name: 'abc', embedded: { a: nil, b: { abc: 'def' } })
        end
      end

      context '#attr_path' do
        it 'for all kinds of attributes' do
          module EntitySpec
            class EmailEntity < Grape::Entity
              expose(:email, as: :addr) { |_, o| o[:attr_path].join('/') }
            end

            class UserEntity < Grape::Entity
              expose(:name, as: :full_name) { |_, o| o[:attr_path].join('/') }
              expose :email, using: 'EntitySpec::EmailEntity'
            end

            class ExtraEntity < Grape::Entity
              expose(:key) { |_, o| o[:attr_path].join('/') }
              expose(:value) { |_, o| o[:attr_path].join('/') }
            end

            class NestedEntity < Grape::Entity
              expose(:name) { |_, o| o[:attr_path].join('/') }
              expose :data, using: 'EntitySpec::ExtraEntity'
            end
          end

          fresh_class.class_eval do
            expose(:id) { |_, o| o[:attr_path].join('/') }
            expose(:foo, as: :bar) { |_, o| o[:attr_path].join('/') }
            expose :title do
              expose :full do
                expose(:prefix, as: :pref) { |_, o| o[:attr_path].join('/') }
                expose(:main) { |_, o| o[:attr_path].join('/') }
              end
            end
            expose :friends, as: :social, using: 'EntitySpec::UserEntity'
            expose :extra, using: 'EntitySpec::ExtraEntity'
            expose :nested, using: 'EntitySpec::NestedEntity'
          end

          expect(subject.serializable_hash).to eq(
            id: 'id',
            bar: 'bar',
            title: { full: { pref: 'title/full/pref', main: 'title/full/main' } },
            social: [
              { full_name: 'social/full_name', email: { addr: 'social/email/addr' } },
              { full_name: 'social/full_name', email: { addr: 'social/email/addr' } }
            ],
            extra: { key: 'extra/key', value: 'extra/value' },
            nested: [
              { name: 'nested/name', data: { key: 'nested/data/key', value: 'nested/data/value' } },
              { name: 'nested/name', data: { key: 'nested/data/key', value: 'nested/data/value' } }
            ]
          )
        end

        it 'allows customize path of an attribute' do
          module EntitySpec
            class CharacterEntity < Grape::Entity
              expose(:key) { |_, o| o[:attr_path].join('/') }
              expose(:value) { |_, o| o[:attr_path].join('/') }
            end
          end

          fresh_class.class_eval do
            expose :characteristics, using: EntitySpec::CharacterEntity,
                                     attr_path: ->(_obj, _opts) { :character }
          end

          expect(subject.serializable_hash).to eq(
            characteristics: [
              { key: 'character/key', value: 'character/value' }
            ]
          )
        end

        it 'can drop one nest level by set path_for to nil' do
          module EntitySpec
            class NoPathCharacterEntity < Grape::Entity
              expose(:key) { |_, o| o[:attr_path].join('/') }
              expose(:value) { |_, o| o[:attr_path].join('/') }
            end
          end

          fresh_class.class_eval do
            expose :characteristics, using: EntitySpec::NoPathCharacterEntity, attr_path: proc { nil }
          end

          expect(subject.serializable_hash).to eq(
            characteristics: [
              { key: 'key', value: 'value' }
            ]
          )
        end
      end

      context 'with projections passed in options' do
        it 'allows to pass different :only and :except params using the same instance' do
          fresh_class.expose :a, :b, :c
          presenter = fresh_class.new(a: 1, b: 2, c: 3)
          expect(presenter.serializable_hash(only: [:a, :b])).to eq(a: 1, b: 2)
          expect(presenter.serializable_hash(only: [:b, :c])).to eq(b: 2, c: 3)
        end
      end
    end

    describe '#inspect' do
      before do
        fresh_class.class_eval do
          expose :name, :email
        end
      end

      it 'does not serialize delegator or options' do
        data = subject.inspect
        expect(data).to include 'name='
        expect(data).to include 'email='
        expect(data).to_not include '@options'
        expect(data).to_not include '@delegator'
      end
    end

    describe '#value_for' do
      before do
        fresh_class.class_eval do
          expose :name, :email
          expose :friends, using: self
          expose :computed do |_, options|
            options[:awesome]
          end

          expose :birthday, format_with: :timestamp

          def timestamp(date)
            date.strftime('%m/%d/%Y')
          end

          expose :fantasies, format_with: ->(f) { f.reverse }
        end
      end

      it 'passes through bare expose attributes' do
        expect(subject.value_for(:name)).to eq attributes[:name]
      end

      it 'instantiates a representation if that is called for' do
        rep = subject.value_for(:friends)
        expect(rep.reject { |r| r.is_a?(fresh_class) }).to be_empty
        expect(rep.first.serializable_hash[:name]).to eq 'Friend 1'
        expect(rep.last.serializable_hash[:name]).to eq 'Friend 2'
      end

      context 'child representations' do
        after { EntitySpec::FriendEntity.unexpose_all }

        it 'disables root key name for child representations' do
          module EntitySpec
            class FriendEntity < Grape::Entity
              root 'friends', 'friend'
              expose :name, :email
            end
          end

          fresh_class.class_eval do
            expose :friends, using: EntitySpec::FriendEntity
          end

          rep = subject.value_for(:friends)
          expect(rep).to be_kind_of Array
          expect(rep.reject { |r| r.is_a?(EntitySpec::FriendEntity) }).to be_empty
          expect(rep.first.serializable_hash[:name]).to eq 'Friend 1'
          expect(rep.last.serializable_hash[:name]).to eq 'Friend 2'
        end

        it 'passes through the proc which returns an array of objects with custom options(:using)' do
          module EntitySpec
            class FriendEntity < Grape::Entity
              root 'friends', 'friend'
              expose :name, :email
            end
          end

          fresh_class.class_eval do
            expose :custom_friends, using: EntitySpec::FriendEntity do |user, _opts|
              user.friends
            end
          end

          rep = subject.value_for(:custom_friends)
          expect(rep).to be_kind_of Array
          expect(rep.reject { |r| r.is_a?(EntitySpec::FriendEntity) }).to be_empty
          expect(rep.first.serializable_hash).to eq(name: 'Friend 1', email: 'friend1@example.com')
          expect(rep.last.serializable_hash).to eq(name: 'Friend 2', email: 'friend2@example.com')
        end

        it 'passes through the proc which returns single object with custom options(:using)' do
          module EntitySpec
            class FriendEntity < Grape::Entity
              root 'friends', 'friend'
              expose :name, :email
            end
          end

          fresh_class.class_eval do
            expose :first_friend, using: EntitySpec::FriendEntity do |user, _opts|
              user.friends.first
            end
          end

          rep = subject.value_for(:first_friend)
          expect(rep).to be_kind_of EntitySpec::FriendEntity
          expect(rep.serializable_hash).to eq(name: 'Friend 1', email: 'friend1@example.com')
        end

        it 'passes through the proc which returns empty with custom options(:using)' do
          module EntitySpec
            class FriendEntity < Grape::Entity
              root 'friends', 'friend'
              expose :name, :email
            end
          end

          fresh_class.class_eval do
            expose :first_friend, using: EntitySpec::FriendEntity do |_user, _opts|
            end
          end

          rep = subject.value_for(:first_friend)
          expect(rep).to be_kind_of EntitySpec::FriendEntity
          expect(rep.serializable_hash).to be_nil
        end

        it 'passes through exposed entity with key and value attributes' do
          module EntitySpec
            class CharacteristicsEntity < Grape::Entity
              root 'characteristics', 'characteristic'
              expose :key, :value
            end
          end

          fresh_class.class_eval do
            expose :characteristics, using: EntitySpec::CharacteristicsEntity
          end

          rep = subject.value_for(:characteristics)
          expect(rep).to be_kind_of Array
          expect(rep.reject { |r| r.is_a?(EntitySpec::CharacteristicsEntity) }).to be_empty
          expect(rep.first.serializable_hash[:key]).to eq 'hair_color'
          expect(rep.first.serializable_hash[:value]).to eq 'brown'
        end

        it 'passes through custom options' do
          module EntitySpec
            class FriendEntity < Grape::Entity
              root 'friends', 'friend'
              expose :name
              expose :email, if: { user_type: :admin }
            end
          end

          fresh_class.class_eval do
            expose :friends, using: EntitySpec::FriendEntity
          end

          rep = subject.value_for(:friends)
          expect(rep).to be_kind_of Array
          expect(rep.reject { |r| r.is_a?(EntitySpec::FriendEntity) }).to be_empty
          expect(rep.first.serializable_hash[:email]).to be_nil
          expect(rep.last.serializable_hash[:email]).to be_nil

          rep = subject.value_for(:friends, Grape::Entity::Options.new(user_type: :admin))
          expect(rep).to be_kind_of Array
          expect(rep.reject { |r| r.is_a?(EntitySpec::FriendEntity) }).to be_empty
          expect(rep.first.serializable_hash[:email]).to eq 'friend1@example.com'
          expect(rep.last.serializable_hash[:email]).to eq 'friend2@example.com'
        end

        it 'ignores the :collection parameter in the source options' do
          module EntitySpec
            class FriendEntity < Grape::Entity
              root 'friends', 'friend'
              expose :name
              expose :email, if: { collection: true }
            end
          end

          fresh_class.class_eval do
            expose :friends, using: EntitySpec::FriendEntity
          end

          rep = subject.value_for(:friends, Grape::Entity::Options.new(collection: false))
          expect(rep).to be_kind_of Array
          expect(rep.reject { |r| r.is_a?(EntitySpec::FriendEntity) }).to be_empty
          expect(rep.first.serializable_hash[:email]).to eq 'friend1@example.com'
          expect(rep.last.serializable_hash[:email]).to eq 'friend2@example.com'
        end
      end

      it 'calls through to the proc if there is one' do
        expect(subject.value_for(:computed, Grape::Entity::Options.new(awesome: 123))).to eq 123
      end

      it 'returns a formatted value if format_with is passed' do
        expect(subject.value_for(:birthday)).to eq '02/27/2012'
      end

      it 'returns a formatted value if format_with is passed a lambda' do
        expect(subject.value_for(:fantasies)).to eq ['Nessy', 'Double Rainbows', 'Unicorns']
      end

      context 'delegate_attribute' do
        module EntitySpec
          class DelegatingEntity < Grape::Entity
            root 'friends', 'friend'
            expose :name
            expose :email
            expose :system

            private

            def name
              'cooler name'
            end
          end
        end

        it 'tries instance methods on the entity first' do
          friend = double('Friend', name: 'joe', email: 'joe@example.com')
          rep = EntitySpec::DelegatingEntity.new(friend)
          expect(rep.value_for(:name)).to eq 'cooler name'
          expect(rep.value_for(:email)).to eq 'joe@example.com'

          another_friend = double('Friend', email: 'joe@example.com')
          rep = EntitySpec::DelegatingEntity.new(another_friend)
          expect(rep.value_for(:name)).to eq 'cooler name'
        end

        it 'does not delegate Kernel methods' do
          foo = double 'Foo', system: 'System'
          rep = EntitySpec::DelegatingEntity.new foo
          expect(rep.value_for(:system)).to eq 'System'
        end

        module EntitySpec
          class DerivedEntity < DelegatingEntity
          end
        end

        it 'derived entity get methods from base entity' do
          foo = double 'Foo', name: 'joe'
          rep = EntitySpec::DerivedEntity.new foo
          expect(rep.value_for(:name)).to eq 'cooler name'
        end
      end

      context 'using' do
        before do
          module EntitySpec
            class UserEntity < Grape::Entity
              expose :name, :email
            end
          end
        end
        it 'string' do
          fresh_class.class_eval do
            expose :friends, using: 'EntitySpec::UserEntity'
          end

          rep = subject.value_for(:friends)
          expect(rep).to be_kind_of Array
          expect(rep.size).to eq 2
          expect(rep.all? { |r| r.is_a?(EntitySpec::UserEntity) }).to be true
        end

        it 'class' do
          fresh_class.class_eval do
            expose :friends, using: EntitySpec::UserEntity
          end

          rep = subject.value_for(:friends)
          expect(rep).to be_kind_of Array
          expect(rep.size).to eq 2
          expect(rep.all? { |r| r.is_a?(EntitySpec::UserEntity) }).to be true
        end
      end
    end

    describe '.documentation' do
      it 'returns an empty hash is no documentation is provided' do
        fresh_class.expose :name

        expect(subject.documentation).to eq({})
      end

      it 'returns each defined documentation hash' do
        doc = { type: 'foo', desc: 'bar' }
        fresh_class.expose :name, documentation: doc
        fresh_class.expose :email, documentation: doc
        fresh_class.expose :birthday

        expect(subject.documentation).to eq(name: doc, email: doc)
      end

      it 'returns each defined documentation hash with :as param considering' do
        doc = { type: 'foo', desc: 'bar' }
        fresh_class.expose :name, documentation: doc, as: :label
        fresh_class.expose :email, documentation: doc
        fresh_class.expose :birthday

        expect(subject.documentation).to eq(label: doc, email: doc)
      end

      it 'resets memoization when exposing additional attributes' do
        fresh_class.expose :x, documentation: { desc: 'just x' }
        expect(fresh_class.instance_variable_get(:@documentation)).to be_nil
        doc1 = fresh_class.documentation
        expect(fresh_class.instance_variable_get(:@documentation)).not_to be_nil
        fresh_class.expose :y, documentation: { desc: 'just y' }
        expect(fresh_class.instance_variable_get(:@documentation)).to be_nil
        doc2 = fresh_class.documentation
        expect(doc1).to eq(x: { desc: 'just x' })
        expect(doc2).to eq(x: { desc: 'just x' }, y: { desc: 'just y' })
      end

      context 'inherited documentation' do
        it 'returns documentation from ancestor' do
          doc = { type: 'foo', desc: 'bar' }
          fresh_class.expose :name, documentation: doc
          child_class = Class.new(fresh_class)
          child_class.expose :email, documentation: doc

          expect(fresh_class.documentation).to eq(name: doc)
          expect(child_class.documentation).to eq(name: doc, email: doc)
        end

        it 'obeys unexposed attributes in subclass' do
          doc = { type: 'foo', desc: 'bar' }
          fresh_class.expose :name, documentation: doc
          fresh_class.expose :email, documentation: doc
          child_class = Class.new(fresh_class)
          child_class.unexpose :email

          expect(fresh_class.documentation).to eq(name: doc, email: doc)
          expect(child_class.documentation).to eq(name: doc)
        end

        it 'obeys re-exposed attributes in subclass' do
          doc = { type: 'foo', desc: 'bar' }
          fresh_class.expose :name, documentation: doc
          fresh_class.expose :email, documentation: doc

          child_class = Class.new(fresh_class)
          child_class.unexpose :email

          nephew_class = Class.new(child_class)
          new_doc = { type: 'todler', descr: '???' }
          nephew_class.expose :email, documentation: new_doc

          expect(fresh_class.documentation).to eq(name: doc, email: doc)
          expect(child_class.documentation).to eq(name: doc)
          expect(nephew_class.documentation).to eq(name: doc, email: new_doc)
        end

        it 'includes only root exposures' do
          fresh_class.expose :name, documentation: { desc: 'foo' }
          fresh_class.expose :nesting do
            fresh_class.expose :smth, documentation: { desc: 'should not be seen' }
          end
          expect(fresh_class.documentation).to eq(name: { desc: 'foo' })
        end
      end
    end

    describe '::DSL' do
      subject { Class.new }

      it 'creates an Entity class when called' do
        expect(subject).not_to be_const_defined :Entity
        subject.send(:include, Grape::Entity::DSL)
        expect(subject).to be_const_defined :Entity
      end

      context 'pre-mixed' do
        before { subject.send(:include, Grape::Entity::DSL) }

        it 'is able to define entity traits through DSL' do
          subject.entity do
            expose :name
          end

          expect(subject.entity_class.root_exposures).not_to be_empty
        end

        it 'is able to expose straight from the class' do
          subject.entity :name, :email
          expect(subject.entity_class.root_exposures.size).to eq 2
        end

        it 'is able to mix field and advanced.root_exposures' do
          subject.entity :name, :email do
            expose :third
          end
          expect(subject.entity_class.root_exposures.size).to eq 3
        end

        context 'instance' do
          let(:instance) { subject.new }

          describe '#entity' do
            it 'is an instance of the entity class' do
              expect(instance.entity).to be_kind_of(subject.entity_class)
            end

            it 'has an object of itself' do
              expect(instance.entity.object).to eq instance
            end

            it 'instantiates with options if provided' do
              expect(instance.entity(awesome: true).options).to eq(awesome: true)
            end
          end
        end
      end
    end

    describe Grape::Entity::Options do
      module EntitySpec
        class Crystalline
          attr_accessor :prop1, :prop2

          def initialize
            @prop1 = 'value1'
            @prop2 = 'value2'
          end
        end

        class CrystallineEntity < Grape::Entity
          expose :prop1, if: ->(_, options) { options.fetch(:signal) }
          expose :prop2, if: ->(_, options) { options.fetch(:beam, 'destructive') == 'destructive' }
        end
      end

      context '#fetch' do
        it 'without passing in a required option raises KeyError' do
          expect { EntitySpec::CrystallineEntity.represent(EntitySpec::Crystalline.new).as_json }.to raise_error KeyError
        end

        it 'passing in a required option will expose the values' do
          crystalline_entity = EntitySpec::CrystallineEntity.represent(EntitySpec::Crystalline.new, signal: true)
          expect(crystalline_entity.as_json).to eq(prop1: 'value1', prop2: 'value2')
        end

        it 'with an option that is not default will not expose that value' do
          crystalline_entity = EntitySpec::CrystallineEntity.represent(EntitySpec::Crystalline.new, signal: true, beam: 'intermittent')
          expect(crystalline_entity.as_json).to eq(prop1: 'value1')
        end
      end
    end
  end
end
