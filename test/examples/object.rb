require "test_helper"

require "ostruct"
require "pp"

source = OpenStruct.new(
  name: "30 Years Live", songs: [
  OpenStruct.new(id: 1, title: "Dear Beloved"), OpenStruct.new(id: 2, title: "Fuck Armageddon")
]
)

require "representable/object"

class AlbumRepresenter < Representable::Decorator
  include Representable::Object

  property :name
  collection :songs, instance: ->(_fragment, *) { Song.new } do
    property :title
  end
end

Album = Struct.new(:name, :songs)
Song = Struct.new(:title)

target = Album.new

AlbumRepresenter.new(target).from_object(source)

# Representing to_object:

class Animal
  attr_accessor :name, :age, :species
  def initialize(name, age, species)
    @name = name
    @age = age
    @species = species
  end
end

require "representable/object"

class AnimalRepresenter < Representable::Decorator
  include Representable::Object

  property :name, getter: ->(represented:, **) { represented.name.upcase }
  property :age
end

animal = Animal.new('Smokey',12,'c')
animal_repr = AnimalRepresenter.new(animal).to_object(wrap: "wrapper")

animal_array = [Animal.new('Shepard',22,'s'),Animal.new('Pickle',12,'c'),Animal.new('Rodgers',55,'e')]
array_repr = AnimalRepresenter.for_collection.new(animal_array).to_object

