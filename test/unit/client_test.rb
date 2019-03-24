require 'test_helper'

describe GraphQL::Client do
  before do
    requests.clear
  end

  describe ".lookup_graphql_file" do
    it "returns the path to the matching graph file" do
      assert_equal "#{PROJECT_DIR}/test/fixtures/metaphysics/artist.graphql", Metaphysics.resolve_graphql_file_path("artist")
    end

    it "returns nil if the file is missing" do
      assert_nil Metaphysics.resolve_graphql_file_path("does_not_exist")
    end
  end

  describe ".graphql_file_paths" do
    it "returns a list of GraphQL files (*.graphql) in the query_paths" do
      Metaphysics.instance_variable_set :@graphql_file_paths, nil
      original = Metaphysics.query_paths

      Metaphysics.query_paths = [File.join(PROJECT_DIR, 'tmp')]

      begin
        FileUtils.mkdir "./tmp/metaphysics" if !Dir.exist?("./tmp/metaphysics")

        with_files "./tmp/metaphysics/text.txt", "./tmp/metaphysics/sale.graphql" do
          assert_equal ["#{PROJECT_DIR}/tmp/metaphysics/sale.graphql"], Metaphysics.graphql_file_paths
        end
      ensure
        Metaphysics.instance_variable_set :@graphql_file_paths, nil
        Metaphysics.query_paths = original
      end
    end
  end

  it "can make a GraphQL request without variables" do
    Metaphysics.artwork

    request = requests[0]

    assert_equal 'Metaphysics__Artwork', request.operation_name
    assert_equal({}, request.variables)
    assert_equal({}, request.context)
    assert_equal <<~GRAPHQL.strip, request.document.to_query_string
      query Metaphysics__Artwork {
        artwork(id: "yayoi-kusama-pumpkin-yellow-and-black") {
          title
          artist {
            name
          }
        }
      }
    GRAPHQL
  end

  it "can make a GraphQL request with variables" do
    Metaphysics.artist(id: "yayoi-kusama")

    request = requests[0]

    assert_equal 'Metaphysics__Artist', request.operation_name
    assert_equal({ 'id' => 'yayoi-kusama' }, request.variables)
    assert_equal({}, request.context)
    assert_equal <<~GRAPHQL.strip, request.document.to_query_string
      query Metaphysics__Artist($id: String!) {
        artist(id: $id) {
          name
          bio
          birthday
        }
      }
    GRAPHQL
  end

  it "can make a GraphQL request with a query that contains fragments" do
    Metaphysics.artists(size: 10)

    request = requests[0]

    assert_equal 'Metaphysics__Artists', request.operation_name
    assert_equal({ 'size' => 10 }, request.variables)
    assert_equal({}, request.context)
    assert_equal <<~GRAPHQL.strip, request.document.to_query_string
      query Metaphysics__Artists($size: Int!) {
        artists(size: $size) {
          name
          bio
          birthday
          ...Metaphysics__ArtistFragment
        }
      }

      fragment Metaphysics__ArtistFragment on Artist {
        hometown
        deathday
      }
    GRAPHQL
  end

  it "can make a GraphQL request with #execute" do
    Metaphysics.execute(:artist, id: "yayoi-kusama")

    request = requests[0]

    assert_equal 'Metaphysics__Artist', request.operation_name
    assert_equal({ 'id' => 'yayoi-kusama' }, request.variables)
    assert_equal({}, request.context)
    assert_equal <<~GRAPHQL.strip, request.document.to_query_string
      query Metaphysics__Artist($id: String!) {
        artist(id: $id) {
          name
          bio
          birthday
        }
      }
    GRAPHQL
  end

  it "can make a GraphQL request with #execute" do
    error = assert_raises Artemis::GraphQLFileNotFound do
      Metaphysics.execute(:does_not_exist)
    end

    assert_match /Query does_not_exist\.graphql not found/, error.message
  end

  it "assigns context to the request when provided as an argument" do
    context = { headers: { Authorization: 'bearer ...' } }

    Metaphysics.artist(id: "yayoi-kusama", context: context)

    assert_equal context, requests[0].context
  end

  it "can create a client that always assigns the provided context to the request" do
    context   = { headers: { Authorization: 'bearer ...' } }
    client    = Metaphysics.with_context(context)

    client.artist(id: "yayoi-kusama")
    client.artist(id: "yayoi-kusama")

    assert_equal context, requests[0].context
    assert_equal context, requests[1].context
  end

  it "assigns the default context to a GraphQL request if present" do
    begin
      Metaphysics.default_context = { headers: { Authorization: 'bearer ...' } }
      Metaphysics.artist(id: "yayoi-kusama")

      assert_equal({ headers: { Authorization: 'bearer ...' } }, requests[0].context)
    ensure
      Metaphysics.default_context = { }
    end
  end

  it "can make a GraphQL request with all of .default_context, with_context(...) and the :context argument" do
    begin
      Metaphysics.default_context = { headers: { 'User-Agent': 'Artemis', 'X-key': 'value', Authorization: 'token ...' } }
      Metaphysics
          .with_context({ headers: { 'X-key': 'overridden' } })
          .artist(id: "yayoi-kusama", context: { headers: { Authorization: 'bearer ...' } })

      assert_equal(requests[0].context, {
        headers: {
          'User-Agent': 'Artemis',
          'X-key': 'overridden',
          Authorization: 'bearer ...',
        }
      })
    ensure
      Metaphysics.default_context = { }
    end
  end

  private

  def requests
    Artemis::Adapters::TestAdapter.requests
  end

  def with_files(*files)
    files.each {|file| FileUtils.touch(file) }
    yield
  ensure
    files.each {|file| File.delete(file) }
  end
end
