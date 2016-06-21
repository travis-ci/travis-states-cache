describe Travis::States::Cache::Serialize do
  let(:data)        { { build_id: 1, state: 'success' } }
  let(:serialize)   { described_class.serialize(data, format: format) }
  let(:deserialize) { described_class.deserialize(string) }

  describe 'json' do
    let(:format) { :json }
    let(:string) { '{"build_id":1,"state":"success"}' }
    let(:branch) { 'main' }

    it { expect(serialize).to eq string }
    it { expect(deserialize).to eq build_id: 1, state: 'success' }
  end

  describe 'string' do
    let(:format) { :string }
    let(:branch) { nil }

    describe 'branch given' do
      let(:string) { '1:success' }
      let(:branch) { 'main' }

      it { expect(serialize).to eq string }
      it { expect(deserialize).to eq build_id: 1, state: 'success' }
    end

    describe 'no branch given' do
      let(:string) { '1:success' }
      let(:branch) { nil }

      it { expect(serialize).to eq string }
      it { expect(deserialize).to eq build_id: 1, state: 'success' }
    end
  end
end
