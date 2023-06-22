require "test_helper"
require "representable/object"

class ObjectTest < MiniTest::Spec
  Song  = Struct.new(:title, :album)
  Album = Struct.new(:name, :songs)

  representer!(module: Representable::Object) do
    property :title

    property :album, instance: ->(options) { options[:fragment].name.upcase!; options[:fragment] } do
      property :name

      collection :songs, instance: ->(options) { options[:fragment].title.upcase!; options[:fragment] } do
        property :title
      end
    end
    # TODO: collection
  end

  let(:source) { Song.new("The King Is Dead", Album.new("Ruiner", [Song.new("In Vino Veritas II")])) }
  let(:target) { Song.new }

  it do
    representer.prepare(target).from_object(source)

    _(target.title).must_equal "The King Is Dead"
    _(target.album.name).must_equal "RUINER"
    _(target.album.songs[0].title).must_equal "IN VINO VERITAS II"
  end

  # ignore nested object when nil
  it do
    representer.prepare(Song.new("The King Is Dead")).from_object(Song.new)

    _(target.title).must_be_nil # scalar property gets overridden when nil.
    _(target.album).must_be_nil # nested property stays nil.
  end

  # to_object
  describe "#to_object" do
    representer!(module: Representable::Object) do
      property :title

      property :album, render_filter: ->(input, _options) { input.name = "Live"; input } do
        property :name

        collection :songs, render_filter: ->(input, _options) { input[0].title = 1; input } do
          property :title
        end
      end
    end

    # it do
    #   representer.prepare(source).to_object
    #   _(source.album.name).must_equal "Live"
    #   _(source.album.songs[0].title).must_equal 1
    # end
  end
end

class ObjectPublicMethodsTest < Minitest::Spec
  Song  = Struct.new(:title, :album)
  Album = Struct.new(:id, :name, :songs, :free_concert_ticket_promo_code)
  class AlbumRepresenter < Representable::Decorator
    include Representable::Object
    property :id
    property :name, getter: ->(*) { name.lstrip.strip }
    property :cover_png, getter: ->(options:, **) { options[:cover_png] }
    collection :songs do
      property :title, getter: ->(*) { title.upcase }
      property :album, getter: ->(*) { album.upcase }
    end
  end

  #---
  # to_object
  let(:album) { Album.new(1, "  Rancid   ", [Song.new("In Vino Veritas II", "Rancid"), Song.new("The King Is Dead", "Rancid")], "S3KR3TK0D3") }
  let(:cover_png) { "example.com/cover.png" }
  it do
    represented = AlbumRepresenter.new(album).to_object(cover_png: cover_png)
    _(represented.id).must_equal album.id
    _(represented.name).wont_equal album.name
    _(represented.name).must_equal album.name.lstrip.strip
    _(represented.songs[0].title).wont_equal album.songs[0].title
    _(represented.songs[0].title).must_equal album.songs[0].title.upcase

    _(album.respond_to?(:free_concert_ticket_promo_code)).must_equal true
    _(represented.respond_to?(:free_concert_ticket_promo_code)).must_equal false

    _(represented.cover_png).must_equal cover_png
  end

  it do
    represented = AlbumRepresenter.new(album).to_object(cover_png: cover_png)
    _(represented.id).must_equal album.id
    _(represented.name).wont_equal album.name
    _(represented.name).must_equal album.name.lstrip.strip
    _(represented.songs[0].title).wont_equal album.songs[0].title
    _(represented.songs[0].title).must_equal album.songs[0].title.upcase

    _(album.respond_to?(:free_concert_ticket_promo_code)).must_equal true
    _(represented.respond_to?(:free_concert_ticket_promo_code)).must_equal false

    _(represented.cover_png).must_equal cover_png
  end

  let(:albums) do  [
    Album.new(1, "Rancid", [Song.new("In Vino Veritas II", "Rancid"), Song.new("The King Is Dead", "Rancid")], "S3KR3TK0D3"),
    Album.new(2, "Punk powerhouse", [Song.new("Hard Outside The Box", "Punk powerhous"), Song.new("Wonderful Noise", "Punk powerhous")], "S3KR3TK0D3"),
    Album.new(3, "Into the Beyond", [Song.new("Rhythm of the night", "Into the Beyond"), Song.new("I'm blue", "Into the Beyond")], "S3KR3TK0D3"),
  ]
  end

  it do
    represented = AlbumRepresenter.for_collection.new(albums).to_object(cover_png: cover_png)
    _(represented.size).must_equal albums.size
    _(albums[0].respond_to?(:free_concert_ticket_promo_code)).must_equal true
    _(represented[0].respond_to?(:free_concert_ticket_promo_code)).must_equal false
    _(represented[0].cover_png).must_equal cover_png
    _(represented[0].class.object_id).must_equal represented[1].class.object_id
  end

  let(:wrapper) { "cool_album" }
  let(:second_wrapper) { "magnificent_album" }
  it do
    represented_array = AlbumRepresenter.for_collection.new(albums).to_object(wrap: wrapper)
    represented_object = AlbumRepresenter.new(album).to_object(wrap: second_wrapper)
    _(represented_array[0].respond_to?(wrapper)).must_equal true
    _(represented_array[0].send(wrapper).songs[0].name).must_equal albums[0].songs[0].name

    _(represented_array[0].class.object_id).must_equal represented_array[1].class.object_id # wrapper struct class is the same for collection
    _(represented_array[0].class.object_id).wont_equal represented_object.class.object_id   # wrapper structs classes are different for different wrappers
  end
end
