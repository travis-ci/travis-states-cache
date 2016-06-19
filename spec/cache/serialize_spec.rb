describe Travis::States::Cache::Serialize do
  let(:data)        { { repo_id: 1, branch: branch, build_id: 1, state: 'success' } }
  let(:serialize)   { described_class.serialize(data, format: format) }
  let(:deserialize) { described_class.deserialize(string, format: format) }

  describe 'json' do
    let(:format) { :json }
    let(:string) { '{"repo_id":1,"branch":"main","build_id":1,"state":"success"}' }
    let(:branch) { 'main' }

    it { expect(serialize).to eq string }
    it { expect(deserialize).to eq data }
  end

  describe 'string' do
    let(:format) { :string }
    let(:branch) { nil }

    describe 'branch given' do
      let(:string) { '1:main:1:success' }
      let(:branch) { 'main' }

      it { expect(serialize).to eq string }
      it { expect(deserialize).to eq data }
    end

    describe 'no branch given' do
      let(:string) { '1::1:success' }
      let(:branch) { nil }

      it { expect(serialize).to eq string }
      it { expect(deserialize).to eq data }
    end
  end
end
