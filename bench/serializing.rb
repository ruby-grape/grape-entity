$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'grape-entity'
require 'benchmark'

module Models
  class School
    attr_reader :classrooms
    def initialize
      @classrooms = []
    end
  end

  class ClassRoom
    attr_reader :students
    attr_accessor :teacher
    def initialize(opts = {})
      @teacher = opts[:teacher]
      @students = []
    end
  end

  class Person
    attr_accessor :name
    def initialize(opts = {})
      @name = opts[:name]
    end
  end

  class Teacher < Models::Person
    attr_accessor :tenure
    def initialize(opts = {})
      super(opts)
      @tenure = opts[:tenure]
    end
  end

  class Student < Models::Person
    attr_reader :grade
    def initialize(opts = {})
      super(opts)
      @grade = opts[:grade]
    end
  end
end

module Entities
  class School < Grape::Entity
    expose :classrooms, using: 'Entities::ClassRoom'
  end

  class ClassRoom < Grape::Entity
    expose :teacher, using: 'Entities::Teacher'
    expose :students, using: 'Entities::Student'
    expose :size do |model, _opts|
      model.students.count
    end
  end

  class Person < Grape::Entity
    expose :name
  end

  class Student < Entities::Person
    expose :grade
    expose :failing do |model, _opts|
      model.grade == 'F'
    end
  end

  class Teacher < Entities::Person
    expose :tenure
  end
end

teacher1 = Models::Teacher.new(name: 'John Smith', tenure: 2)
classroom1 = Models::ClassRoom.new(teacher: teacher1)
classroom1.students << Models::Student.new(name: 'Bobby', grade: 'A')
classroom1.students << Models::Student.new(name: 'Billy', grade: 'B')

teacher2 = Models::Teacher.new(name: 'Lisa Barns')
classroom2 = Models::ClassRoom.new(teacher: teacher2, tenure: 15)
classroom2.students << Models::Student.new(name: 'Eric', grade: 'A')
classroom2.students << Models::Student.new(name: 'Eddie', grade: 'C')
classroom2.students << Models::Student.new(name: 'Arnie', grade: 'C')
classroom2.students << Models::Student.new(name: 'Alvin', grade: 'F')
school = Models::School.new
school.classrooms << classroom1
school.classrooms << classroom2

iters = 5000

Benchmark.bm do |bm|
  bm.report('serializing') do
    iters.times do
      Entities::School.represent(school, serializable: true)
    end
  end
end
