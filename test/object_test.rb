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

    assert_equal target.title, "The King Is Dead"
    assert_equal target.album.name, "RUINER"
    assert_equal target.album.songs[0].title, "IN VINO VERITAS II"
  end

  # ignore nested object when nil
  it do
    representer.prepare(Song.new("The King Is Dead")).from_object(Song.new)

    assert_nil target.title # scalar property gets overridden when nil.
    assert_nil target.album # nested property stays nil.
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
    assert_equal represented.id, album.id
    refute_equal represented.name, album.name
    assert_equal represented.name, album.name.lstrip.strip
    refute_equal represented.songs[0].title, album.songs[0].title
    assert_equal represented.songs[0].title, album.songs[0].title.upcase

    assert_respond_to album, :free_concert_ticket_promo_code
    refute_respond_to represented, :free_concert_ticket_promo_code

    assert_equal represented.cover_png, cover_png
  end

  it do
    represented = AlbumRepresenter.new(album).to_object(cover_png: cover_png)
    assert_equal represented.id, album.id
    refute_equal represented.name, album.name
    assert_equal represented.name, album.name.lstrip.strip
    refute_equal represented.songs[0].title, album.songs[0].title
    assert_equal represented.songs[0].title, album.songs[0].title.upcase

    assert_respond_to album, :free_concert_ticket_promo_code
    refute_respond_to represented, :free_concert_ticket_promo_code

    assert_equal represented.cover_png, cover_png
  end

  let(:albums) do  [
    Album.new(1, "Rancid", [Song.new("In Vino Veritas II", "Rancid"), Song.new("The King Is Dead", "Rancid")], "S3KR3TK0D3"),
    Album.new(2, "Punk powerhouse", [Song.new("Hard Outside The Box", "Punk powerhous"), Song.new("Wonderful Noise", "Punk powerhous")], "S3KR3TK0D3"),
    Album.new(3, "Into the Beyond", [Song.new("Rhythm of the night", "Into the Beyond"), Song.new("I'm blue", "Into the Beyond")], "S3KR3TK0D3"),
  ]
  end

  it do
    represented = AlbumRepresenter.for_collection.new(albums).to_object(cover_png: cover_png)
    assert_equal represented.size, albums.size
    assert_respond_to albums[0], :free_concert_ticket_promo_code
    refute_respond_to represented[0], :free_concert_ticket_promo_code
    assert_equal represented[0].cover_png, cover_png
    assert_equal represented[0].class.object_id, represented[1].class.object_id
  end

  let(:wrapper) { "cool_album" }
  let(:second_wrapper) { "magnificent_album" }
  it do
    represented_array = AlbumRepresenter.for_collection.new(albums).to_object(wrap: wrapper)
    represented_object = AlbumRepresenter.new(album).to_object(wrap: second_wrapper)

    assert_respond_to represented_array, wrapper

    assert_respond_to represented_array.send(wrapper)[0], wrapper
    first_song_title_represented = represented_array.send(wrapper)[0].send(wrapper).songs[0].title
    first_song_title_original = albums[0].songs[0].title
    assert_equal first_song_title_represented, first_song_title_original.upcase

    assert_equal represented_array.send(wrapper)[0].class.object_id, represented_array.send(wrapper)[1].class.object_id # wrapper struct class is the same for collection
    refute_equal represented_array.send(wrapper)[0].class.object_id, represented_object.class.object_id   # wrapper structs classes are different for different wrappers
  end
end
