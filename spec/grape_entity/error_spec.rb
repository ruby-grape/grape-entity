require 'spec_helper'

describe "description" do
  it "complex nested attributes" do
    class ClassRoom < Grape::Entity
      expose(:parents, using: 'Parent') { |_| [{}, {}]}
    end

    class Person < Grape::Entity
      expose :user do
        expose(:id) { |_| 'value' }
      end
    end

    class Student < Person
      expose :user do
        expose(:user_id) { |_| 'value' }
        expose(:user_display_id, as: :display_id) { |_| 'value' }
      end
    end

    class Parent < Person
      expose(:children, using: 'Student') { |_| [{}, {}]}
    end

    ClassRoom.represent({}).serializable_hash.should == {
      :parents => [
        { :children =>
          [
            { user: { user_id: 'value', display_id: 'value' } },
            { user: { user_id: 'value', display_id: 'value' } }
          ]
        }
      ]
    }
  end
end