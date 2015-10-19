require "test_helper"

class PopulatorFindOrInstantiateTest < MiniTest::Spec
  Song = Struct.new(:id, :title, :uid)
  Song.class_eval do
    def self.find_by(attributes={})
      return new(1, "Resist Stan", "abcd") if attributes[:id]==1# we should return the same object here
      new
    end
  end

  describe "collection" do
    representer! do
      collection :songs, populator: Representable::FindOrInstantiate, class: Song do
        property :id
        property :title
      end
    end

    let (:album) { Struct.new(:songs).new([]).extend(representer) }


    it "finds by :id and creates new without :id" do
      album.from_hash({"songs"=>[
        {"id" => 1, "title"=>"Resist Stance"},
        {"title"=>"Suffer"}
      ]})

      album.songs[0].title.must_equal "Resist Stance" # note how title is updated from "Resist Stan"
      album.songs[0].id.must_equal 1
      album.songs[0].uid.must_equal "abcd" # not changed via populator, indicating this is a formerly "persisted" object.

      album.songs[1].title.must_equal "Suffer"
      album.songs[1].id.must_equal nil
      album.songs[1].uid.must_equal nil
    end

    # TODO: test with existing collection
  end

end