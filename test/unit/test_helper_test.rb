require 'test_helper'

require 'artemis/test_helper'
require 'date'

describe Artemis::TestHelper do
  include Artemis::TestHelper

  def graphql_fixture_path
    File.join(PROJECT_DIR, "test/fixtures/responses")
  end

  before do
    graphql_requests.clear
    graphql_responses.clear
  end

  it "can mock a GraphQL request" do
    stub_graphql(Metaphysics, :artist).to_return(:yayoi_kusama)

    response = Metaphysics.artist(id: "yayoi-kusama")

    assert_equal "Yayoi Kusama", response.data.artist.name
    assert_equal "1929/03/22", response.data.artist.birthday
  end

  it "can mock a GraphQL request with an ERB-enabled fixture" do
    stub_graphql(Metaphysics, :artist).to_return(:yuki)

    response = Metaphysics.artist(id: "yuki")

    assert_equal "#{Date.today.year}/01/01", response.data.artist.birthday
  end

  it "can mock a GraphQL request with variables using exact match" do
    stub_graphql(Metaphysics, :artist, id: "yayoi-kusama").to_return(:yayoi_kusama)
    stub_graphql(Metaphysics, :artist, id: "leonardo-da-vinci").to_return(:leonardo_da_vinci)

    yayoi_kusama = Metaphysics.artist(id: "yayoi-kusama")
    da_vinci     = Metaphysics.artist(id: "leonardo-da-vinci")

    assert_equal "Yayoi Kusama", yayoi_kusama.data.artist.name
    assert_equal "Leonardo da Vinci", da_vinci.data.artist.name
  end

  it "can mock a GraphQL request with a JSON file" do
    stub_graphql(Metaphysics, :artwork).to_return(:the_last_supper)

    response = Metaphysics.artwork(id: "leonardo-da-vinci-the-last-supper")

    assert_equal "The Last Supper", response.data.artwork.title
    assert_equal "Leonardo da Vinci", response.data.artwork.artist.name
  end

  it "can mock a GraphQL request for a query that has a query name"

  it "raises an exception if the specified fixture file does not exist" do
    error = assert_raises Artemis::FixtureNotFound do
              stub_graphql(Metaphysics, :does_not_exist)
            end

    assert_match %r|test/fixtures/responses/does_not_exist.{yml,json}|, error.message
  end

  it "raises an exception if the specified fixture file exists but fixture key does not exist" do
    error = assert_raises Artemis::FixtureNotFound do
              stub_graphql(Metaphysics, :artist).to_return(:does_not_exist)
            end

    assert_match %r|test/fixtures/responses/artist.yml|, error.message
  end
end
