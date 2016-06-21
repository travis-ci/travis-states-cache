describe 'Compatibility with travis-core/states_cache' do
  let(:client) { Travis::States::Cache::Adapter::Memory.new }
  let(:record) { Travis::States::Cache::Record.new(client, args) }

  describe 'reading a json value that uses :id as a key for the build id' do
    subject { record.read }

    context 'branch given' do
      let(:args) { { repo_id: 1, branch: 'main' } }
      let(:data) { '{"id":1,"state":"passed"}' }
      before     { client.stubs(:get).with('state:1:main').returns(data) }
      it { should eq(repo_id: 1, build_id: 1, branch: 'main', state: 'passed') }
    end

    context 'no branch given' do
      let(:args) { { repo_id: 1 } }
      let(:data) { '{"id":1,"state":"passed"}' }
      before     { client.stubs(:get).with('state:1').returns(data) }
      it { should eq(repo_id: 1, build_id: 1, branch: nil, state: 'passed') }
    end
  end
end
