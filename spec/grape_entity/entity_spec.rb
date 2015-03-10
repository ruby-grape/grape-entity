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
          expect(subject.exposures.size).to eq 3
        end

        it 'sets the same options for all exposures passed' do
          subject.expose :name, :email, :location, documentation: true
          subject.exposures.values.each { |v| expect(v).to eq(documentation: true) }
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
          value = subject.represent(object).send(:value_for, :bogus)
          expect(value).to be_instance_of EntitySpec::BogusEntity

          prop1 = value.send(:value_for, :prop1)
          expect(prop1).to eq 'MODIFIED 2'
        end

        context 'with parameters passed to the block' do
          it 'sets the :proc option in the exposure options' do
            block = lambda { |_| true }
            subject.expose :name, using: 'Awesome', &block
            expect(subject.exposures[:name]).to eq(proc: block, using: 'Awesome')
          end

          it 'references an instance of the entity without any options' do
            subject.expose(:size) { |_| self }
            expect(subject.represent(Hash.new).send(:value_for, :size)).to be_an_instance_of fresh_class
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

            expect(subject.exposures).to eq(
                                              awesome: {},
                                              awesome__nested: { nested: true },
                                              awesome__nested__moar_nested: { as: 'weee', nested: true },
                                              awesome__another_nested: { using: 'Awesome', nested: true }
            )
          end

          it 'represents the exposure as a hash of its nested exposures' do
            subject.expose :awesome do
              subject.expose(:nested) { |_| 'value' }
              subject.expose(:another_nested) { |_| 'value' }
            end

            expect(subject.represent({}).send(:value_for, :awesome)).to eq(
                                                                             nested: 'value',
                                                                             another_nested: 'value'
            )
          end

          it 'does not represent nested exposures whose conditions are not met' do
            subject.expose :awesome do
              subject.expose(:condition_met, if: lambda { |_, _| true }) { |_| 'value' }
              subject.expose(:condition_not_met, if: lambda { |_, _| false }) { |_| 'value' }
            end

            expect(subject.represent({}).send(:value_for, :awesome)).to eq(condition_met: 'value')
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

          it 'complex nested attributes' do
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

          it 'is safe if its nested exposures are safe' do
            subject.with_options safe: true do
              subject.expose :awesome do
                subject.expose(:nested) { |_| 'value' }
              end
              subject.expose :not_awesome do
                subject.expose :nested
              end
            end

            valid_keys = subject.represent({}).valid_exposures.keys

            expect(valid_keys.include?(:awesome)).to be true
            expect(valid_keys.include?(:not_awesome)).to be false
          end
        end
      end

      context 'inherited exposures' do
        it 'returns exposures from an ancestor' do
          subject.expose :name, :email
          child_class = Class.new(subject)

          expect(child_class.exposures).to eq(subject.exposures)
        end

        it 'returns exposures from multiple ancestor' do
          subject.expose :name, :email
          parent_class = Class.new(subject)
          child_class  = Class.new(parent_class)

          expect(child_class.exposures).to eq(subject.exposures)
        end

        it 'returns descendant exposures as a priority' do
          subject.expose :name, :email
          child_class = Class.new(subject)
          child_class.expose :name do |_|
            'foo'
          end

          expect(subject.exposures[:name]).not_to have_key :proc
          expect(child_class.exposures[:name]).to have_key :proc
        end
      end

      context 'register formatters' do
        let(:date_formatter) { lambda { |date| date.strftime('%m/%d/%Y') } }

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

          model  = { birthday: Time.gm(2012, 2, 27) }
          expect(subject.new(double(model)).as_json[:birthday]).to eq '02/27/2012'
        end

        it 'formats an exposure with a :format_with lambda that returns a value from the entity instance' do
          object = Hash.new

          subject.expose(:size, format_with: lambda { |_value| self.object.class.to_s })
          expect(subject.represent(object).send(:value_for, :size)).to eq object.class.to_s
        end

        it 'formats an exposure with a :format_with symbol that returns a value from the entity instance' do
          subject.format_with :size_formatter do |_date|
            self.object.class.to_s
          end

          object = Hash.new

          subject.expose(:size, format_with: :size_formatter)
          expect(subject.represent(object).send(:value_for, :size)).to eq object.class.to_s
        end
      end
    end

    describe '.unexpose' do
      it 'is able to remove exposed attributes' do
        subject.expose :name, :email
        subject.unexpose :email

        expect(subject.exposures).to eq(name: {})
      end

      context 'inherited exposures' do
        it 'when called from child class, only removes from the attribute from child' do
          subject.expose :name, :email
          child_class = Class.new(subject)
          child_class.unexpose :email

          expect(child_class.exposures).to eq(name: {})
          expect(subject.exposures).to eq(name: {}, email: {})
        end

        # the following 2 behaviors are testing because it is not most intuitive and could be confusing
        context 'when  called from the parent class' do
          it 'remove from parent and all child classes that have not locked down their attributes with an .exposures call' do
            subject.expose :name, :email
            child_class = Class.new(subject)
            subject.unexpose :email

            expect(subject.exposures).to eq(name: {})
            expect(child_class.exposures).to eq(name: {})
          end

          it 'remove from parent and do not remove from child classes that have locked down their attributes with an .exposures call' do
            subject.expose :name, :email
            child_class = Class.new(subject)
            child_class.exposures
            subject.unexpose :email

            expect(subject.exposures).to eq(name: {})
            expect(child_class.exposures).to eq(name: {}, email: {})
          end
        end
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

      it 'applies the options to all exposures inside' do
        subject.class_eval do
          with_options(if: { awesome: true }) do
            expose :awesome_thing, using: 'Awesome'
          end
        end

        expect(subject.exposures[:awesome_thing]).to eq(if: { awesome: true }, using: 'Awesome')
      end

      it 'allows for nested .with_options' do
        subject.class_eval do
          with_options(if: { awesome: true }) do
            with_options(using: 'Something') do
              expose :awesome_thing
            end
          end
        end

        expect(subject.exposures[:awesome_thing]).to eq(if: { awesome: true }, using: 'Something')
      end

      it 'overrides nested :as option' do
        subject.class_eval do
          with_options(as: :sweet) do
            expose :awesome_thing, as: :extra_smooth
          end
        end

        expect(subject.exposures[:awesome_thing]).to eq(as: :extra_smooth)
      end

      it 'merges nested :if option' do
        match_proc = lambda { |_obj, _opts| true }

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

        expect(subject.exposures[:awesome_thing]).to eq(
                                                          if: { awesome: false, less_awesome: true },
                                                          if_extras: [:awesome, match_proc]
        )
      end

      it 'merges nested :unless option' do
        match_proc = lambda { |_, _| true }

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

        expect(subject.exposures[:awesome_thing]).to eq(
                                                          unless: { awesome: false, less_awesome: true },
                                                          unless_extras: [:awesome, match_proc]
        )
      end

      it 'overrides nested :using option' do
        subject.class_eval do
          with_options(using: 'Something') do
            expose :awesome_thing, using: 'SomethingElse'
          end
        end

        expect(subject.exposures[:awesome_thing]).to eq(using: 'SomethingElse')
      end

      it 'aliases :with option to :using option' do
        subject.class_eval do
          with_options(using: 'Something') do
            expose :awesome_thing, with: 'SomethingElse'
          end
        end
        expect(subject.exposures[:awesome_thing]).to eq(using: 'SomethingElse')
      end

      it 'overrides nested :proc option' do
        match_proc = lambda { |_obj, _opts| 'more awesomer' }

        subject.class_eval do
          with_options(proc: lambda { |_obj, _opts| 'awesome' }) do
            expose :awesome_thing, proc: match_proc
          end
        end

        expect(subject.exposures[:awesome_thing]).to eq(proc: match_proc)
      end

      it 'overrides nested :documentation option' do
        subject.class_eval do
          with_options(documentation: { desc: 'Description.' }) do
            expose :awesome_thing, documentation: { desc: 'Other description.' }
          end
        end

        expect(subject.exposures[:awesome_thing]).to eq(documentation: { desc: 'Other description.' })
      end
    end

    describe '.represent' do
      it 'returns a single entity if called with one object' do
        expect(subject.represent(Object.new)).to be_kind_of(subject)
      end

      it 'returns a single entity if called with a hash' do
        expect(subject.represent(Hash.new)).to be_kind_of(subject)
      end

      it 'returns multiple entities if called with a collection' do
        representation = subject.represent(4.times.map { Object.new })
        expect(representation).to be_kind_of Array
        expect(representation.size).to eq(4)
        expect(representation.reject { |r| r.is_a?(subject) }).to be_empty
      end

      it 'adds the collection: true option if called with a collection' do
        representation = subject.represent(4.times.map { Object.new })
        representation.each { |r| expect(r.options[:collection]).to be true }
      end

      it 'returns a serialized hash of a single object if serializable: true' do
        subject.expose(:awesome) { |_| true }
        representation = subject.represent(Object.new, serializable: true)
        expect(representation).to eq(awesome: true)
      end

      it 'returns a serialized array of hashes of multiple objects if serializable: true' do
        subject.expose(:awesome) { |_| true }
        representation = subject.represent(2.times.map { Object.new }, serializable: true)
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
    end

    describe '.present_collection' do
      it 'make the objects accessible' do
        subject.present_collection true
        subject.expose :items

        representation = subject.represent(4.times.map { Object.new })
        expect(representation).to be_kind_of(subject)
        expect(representation.object).to be_kind_of(Hash)
        expect(representation.object).to have_key :items
        expect(representation.object[:items]).to be_kind_of Array
        expect(representation.object[:items].size).to be 4
      end

      it 'serializes items with my root name' do
        subject.present_collection true, :my_items
        subject.expose :my_items

        representation = subject.represent(4.times.map { Object.new }, serializable: true)
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
            representation = subject.represent(4.times.map { Object.new })
            expect(representation).to be_kind_of Hash
            expect(representation).to have_key 'things'
            expect(representation['things']).to be_kind_of Array
            expect(representation['things'].size).to eq 4
            expect(representation['things'].reject { |r| r.is_a?(subject) }).to be_empty
          end
        end

        context 'it can be overridden' do
          it 'can be disabled' do
            representation = subject.represent(4.times.map { Object.new }, root: false)
            expect(representation).to be_kind_of Array
            expect(representation.size).to eq 4
            expect(representation.reject { |r| r.is_a?(subject) }).to be_empty
          end
          it 'can use a different name' do
            representation = subject.represent(4.times.map { Object.new }, root: 'others')
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
            representation = subject.represent(4.times.map { Object.new })
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
            representation = subject.represent(4.times.map { Object.new })
            expect(representation).to be_kind_of Hash
            expect(representation).to have_key('things')
            expect(representation['things']).to be_kind_of Array
            expect(representation['things'].size).to eq 4
            expect(representation['things'].reject { |r| r.is_a?(subject) }).to be_empty
          end
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

        it "does not expose attributes that don't exist on the object" do
          fresh_class.expose :email, :nonexistent_attribute, :name, safe: true

          res = fresh_class.new(model).serializable_hash
          expect(res).to have_key :email
          expect(res).not_to have_key :nonexistent_attribute
          expect(res).to have_key :name
        end

        it 'does expose attributes marked as safe if model is a hash object' do
          fresh_class.expose :name, safe: true

          res = fresh_class.new(name: 'myname').serializable_hash
          expect(res).to have_key :name
        end

        it "does not expose attributes that don't exist on the object, even with criteria" do
          fresh_class.expose :email
          fresh_class.expose :nonexistent_attribute, safe: true, if: lambda { false }
          fresh_class.expose :nonexistent_attribute2, safe: true, if: lambda { true }

          res = fresh_class.new(model).serializable_hash
          expect(res).to have_key :email
          expect(res).not_to have_key :nonexistent_attribute
          expect(res).not_to have_key :nonexistent_attribute2
        end
      end

      context 'without safe option' do
        it 'throws an exception when an attribute is not found on the object' do
          fresh_class.expose :name, :nonexistent_attribute
          expect { fresh_class.new(model).serializable_hash }.to raise_error
        end

        it "exposes attributes that don't exist on the object only when they are generated by a block" do
          fresh_class.expose :nonexistent_attribute do |_model, _opts|
            'well, I do exist after all'
          end
          res = fresh_class.new(model).serializable_hash
          expect(res).to have_key :nonexistent_attribute
        end

        it 'does not expose attributes that are generated by a block but have not passed criteria' do
          fresh_class.expose :nonexistent_attribute, proc: lambda { |_model, _opts|
            'I exist, but it is not yet my time to shine'
          },                                         if: lambda { |_model, _opts| false }
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
        fresh_class.expose :nonexistent_attribute, proc: lambda { |_, _|
          'I exist, but it is not yet my time to shine'
        },                                         if: lambda { |_, _| false }
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

          expose :fantasies, format_with: lambda { |f| f.reverse }
        end
      end

      it 'passes through bare expose attributes' do
        expect(subject.send(:value_for, :name)).to eq attributes[:name]
      end

      it 'instantiates a representation if that is called for' do
        rep = subject.send(:value_for, :friends)
        expect(rep.reject { |r| r.is_a?(fresh_class) }).to be_empty
        expect(rep.first.serializable_hash[:name]).to eq 'Friend 1'
        expect(rep.last.serializable_hash[:name]).to eq 'Friend 2'
      end

      context 'child representations' do
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

          rep = subject.send(:value_for, :friends)
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

          rep = subject.send(:value_for, :custom_friends)
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

          rep = subject.send(:value_for, :first_friend)
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

          rep = subject.send(:value_for, :first_friend)
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

          rep = subject.send(:value_for, :characteristics)
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

          rep = subject.send(:value_for, :friends)
          expect(rep).to be_kind_of Array
          expect(rep.reject { |r| r.is_a?(EntitySpec::FriendEntity) }).to be_empty
          expect(rep.first.serializable_hash[:email]).to be_nil
          expect(rep.last.serializable_hash[:email]).to be_nil

          rep = subject.send(:value_for, :friends,  user_type: :admin)
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

          rep = subject.send(:value_for, :friends,  collection: false)
          expect(rep).to be_kind_of Array
          expect(rep.reject { |r| r.is_a?(EntitySpec::FriendEntity) }).to be_empty
          expect(rep.first.serializable_hash[:email]).to eq 'friend1@example.com'
          expect(rep.last.serializable_hash[:email]).to eq 'friend2@example.com'
        end
      end

      it 'calls through to the proc if there is one' do
        expect(subject.send(:value_for, :computed, awesome: 123)).to eq 123
      end

      it 'returns a formatted value if format_with is passed' do
        expect(subject.send(:value_for, :birthday)).to eq '02/27/2012'
      end

      it 'returns a formatted value if format_with is passed a lambda' do
        expect(subject.send(:value_for, :fantasies)).to eq ['Nessy', 'Double Rainbows', 'Unicorns']
      end

      it 'tries instance methods on the entity first' do
        module EntitySpec
          class DelegatingEntity < Grape::Entity
            root 'friends', 'friend'
            expose :name
            expose :email

            private

            def name
              'cooler name'
            end
          end
        end

        friend = double('Friend', name: 'joe', email: 'joe@example.com')
        rep = EntitySpec::DelegatingEntity.new(friend)
        expect(rep.send(:value_for, :name)).to eq 'cooler name'
        expect(rep.send(:value_for, :email)).to eq 'joe@example.com'
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

          rep = subject.send(:value_for, :friends)
          expect(rep).to be_kind_of Array
          expect(rep.size).to eq 2
          expect(rep.all? { |r| r.is_a?(EntitySpec::UserEntity) }).to be true
        end

        it 'class' do
          fresh_class.class_eval do
            expose :friends, using: EntitySpec::UserEntity
          end

          rep = subject.send(:value_for, :friends)
          expect(rep).to be_kind_of Array
          expect(rep.size).to eq 2
          expect(rep.all? { |r| r.is_a?(EntitySpec::UserEntity) }).to be true
        end
      end
    end

    describe '#documentation' do
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
    end

    describe '#key_for' do
      it 'returns the attribute if no :as is set' do
        fresh_class.expose :name
        expect(subject.class.send(:key_for, :name)).to eq :name
      end

      it 'returns a symbolized version of the attribute' do
        fresh_class.expose :name
        expect(subject.class.send(:key_for, 'name')).to eq :name
      end

      it 'returns the :as alias if one exists' do
        fresh_class.expose :name, as: :nombre
        expect(subject.class.send(:key_for, 'name')).to eq :nombre
      end
    end

    describe '#conditions_met?' do
      it 'only passes through hash :if exposure if all attributes match' do
        exposure_options = { if: { condition1: true, condition2: true } }

        expect(subject.send(:conditions_met?, exposure_options, {})).to be false
        expect(subject.send(:conditions_met?, exposure_options, condition1: true)).to be false
        expect(subject.send(:conditions_met?, exposure_options, condition1: true, condition2: true)).to be true
        expect(subject.send(:conditions_met?, exposure_options, condition1: false, condition2: true)).to be false
        expect(subject.send(:conditions_met?, exposure_options, condition1: true, condition2: true, other: true)).to be true
      end

      it 'looks for presence/truthiness if a symbol is passed' do
        exposure_options = { if: :condition1 }

        expect(subject.send(:conditions_met?, exposure_options, {})).to be false
        expect(subject.send(:conditions_met?, exposure_options,  condition1: true)).to be true
        expect(subject.send(:conditions_met?, exposure_options,  condition1: false)).to be false
        expect(subject.send(:conditions_met?, exposure_options,  condition1: nil)).to be false
      end

      it 'looks for absence/falsiness if a symbol is passed' do
        exposure_options = { unless: :condition1 }

        expect(subject.send(:conditions_met?, exposure_options, {})).to be true
        expect(subject.send(:conditions_met?, exposure_options,  condition1: true)).to be false
        expect(subject.send(:conditions_met?, exposure_options,  condition1: false)).to be true
        expect(subject.send(:conditions_met?, exposure_options,  condition1: nil)).to be true
      end

      it 'only passes through proc :if exposure if it returns truthy value' do
        exposure_options = { if: lambda { |_, opts| opts[:true] } }

        expect(subject.send(:conditions_met?, exposure_options, true: false)).to be false
        expect(subject.send(:conditions_met?, exposure_options, true: true)).to be true
      end

      it 'only passes through hash :unless exposure if any attributes do not match' do
        exposure_options = { unless: { condition1: true, condition2: true } }

        expect(subject.send(:conditions_met?, exposure_options, {})).to be true
        expect(subject.send(:conditions_met?, exposure_options, condition1: true)).to be false
        expect(subject.send(:conditions_met?, exposure_options, condition1: true, condition2: true)).to be false
        expect(subject.send(:conditions_met?, exposure_options, condition1: false, condition2: true)).to be false
        expect(subject.send(:conditions_met?, exposure_options, condition1: true, condition2: true, other: true)).to be false
        expect(subject.send(:conditions_met?, exposure_options, condition1: false, condition2: false)).to be true
      end

      it 'only passes through proc :unless exposure if it returns falsy value' do
        exposure_options = { unless: lambda { |_, options| options[:true] == true } }

        expect(subject.send(:conditions_met?, exposure_options, true: false)).to be true
        expect(subject.send(:conditions_met?, exposure_options, true: true)).to be false
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

          expect(subject.entity_class.exposures).not_to be_empty
        end

        it 'is able to expose straight from the class' do
          subject.entity :name, :email
          expect(subject.entity_class.exposures.size).to eq 2
        end

        it 'is able to mix field and advanced exposures' do
          subject.entity :name, :email do
            expose :third
          end
          expect(subject.entity_class.exposures.size).to eq 3
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
  end
end
