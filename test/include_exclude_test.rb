require "test_helper"

class IncludeExcludeTest < Minitest::Spec
  Song   = Struct.new(:title, :artist)
  Artist = Struct.new(:name, :id)

  representer!(decorator: true) do
    property :title
    property :artist, class: Artist do
      property :name
      property :id
    end
  end

  let (:song) { Song.new("Listless", Artist.new("7yearsbadluck", 1)) }
  let (:decorator) { representer.new(song) }

  describe "#from_hash" do
    it "accepts :exclude option" do
      decorator.from_hash({"title"=>"Don't Smile In Trouble", "artist"=>{"id"=>2}}, exclude: [:title])

      song.title.must_equal "Listless"
      song.artist.must_equal Artist.new(nil, 2)
    end

    it "accepts :include option" do
      decorator.from_hash({"title"=>"Don't Smile In Trouble", "artist"=>{"id"=>2}}, include: [:title])

      song.title.must_equal "Don't Smile In Trouble"
      song.artist.must_equal Artist.new("7yearsbadluck", 1)
    end

    it "accepts nestedx :exclude option" do
      decorator.extend(Representable::Debug).from_hash({"title"=>"Don't Smile In Trouble", "artist"=>{"name"=>"Foo", "id"=>2}},
        exclude: [:title],
        artist: { exclude: [:id] }
      )

      song.title.must_equal "Listless"
      song.artist.must_equal Artist.new("Foo", nil)
    end

    # it "accepts nested :include option" do
    #   decorator.from_hash({"title"=>"Don't Smile In Trouble", "artist"=>{"name"=>"Foo", "id"=>2}}, include: {artist: [:id]})

    #   song.title.must_equal "Listless"
    #   song.artist.must_equal Artist.new("7yearsbadluck", 2)
    # end
  end

  describe "#to_hash" do
    it "accepts :exclude option" do
      decorator.to_hash(exclude: [:title]).must_equal({"artist"=>{"name"=>"7yearsbadluck", "id"=>1}})
    end

    it "accepts :include option" do
      decorator.to_hash(include: [:title]).must_equal({"title"=>"Listless"})
    end

    # it "accepts nested :exclude option" do
    #   decorator.to_hash(exclude: {artist: [:name]}).must_equal({"title"=>"Listless", "artist"=>{"id"=>1}})
    # end

    it "accepts nested :include option" do
      decorator.to_hash(include: [:artist], artist: {include: [:name]}).must_equal({"artist"=>{"name"=>"7yearsbadluck"}})
    end
  end

  it "xdoes not propagate private options to nested objects" do
    Cover = Struct.new(:title, :original)

    cover_rpr = Module.new do
      include Representable::Hash
      property :title
      property :original, extend: self
    end

    # FIXME: we should test all representable-options (:include, :exclude, ?)

    Cover.new("Roxanne", Cover.new("Roxanne (Don't Put On The Red Light)")).extend(cover_rpr).
      to_hash(:include => [:original]).must_equal({"original"=>{"title"=>"Roxanne (Don't Put On The Red Light)"}})
  end
end