describe Travis::States::Cache::Record do
  let(:opts)   { { format: :string } }
  let(:client) { Travis::States::Cache::Adapter::Memory.new }

  describe 'read' do
    subject { described_class.new(client, args, opts).read }

    context 'branch given' do
      let(:args) { { repo_id: 1, branch: 'main' } }
      let(:data) { { repo_id: 1, build_id: 1, branch: 'main', state: 'success' } }
      before     { client.stubs(:get).with('state:1:main').returns('1:success') }

      it { should eq data }
    end

    context 'no branch given' do
      let(:args) { { repo_id: 1 } }
      let(:data) { { repo_id: 1, build_id: 1, branch: nil, state: 'success' } }
      before     { client.stubs(:get).with('state:1').returns('1:success') }

      it { should eq(data) }
    end
  end

  describe 'write' do
    subject { described_class.new(client, args, opts).write('success') }

    context 'branch given' do
      let(:args) { { repo_id: 1, branch: 'main', build_id: 1 } }
      let(:data) { { repo_id: 1, build_id: 1, branch: 'main', state: 'success' } }

      it { expect { subject }.to change { client.get('state:1:main') }.to('1:success') }
      it { expect(subject).to eq(data) }
    end

    context 'no branch given' do
      let(:args) { { repo_id: 1, build_id: 1 } }
      let(:data) { { repo_id: 1, build_id: 1, state: 'success' } }

      it { expect { subject }.to change { client.get('state:1') }.to('1:success') }
      it { expect(subject).to eq(data) }
    end
  end

  describe 'status' do
    let(:args) { { repo_id: 1, build_id: 2 } }
    subject { described_class.new(client, args, opts).status }

    context 'when fresh' do
      before { client.set('state:1', '2:success') }
      it { should be :fresh }
    end

    context 'when stale' do
      before { client.set('state:1', '1:success') }
      it { should be :stale }
    end

    context 'when not cached' do
      it { should be :miss }
    end
  end

  describe 'fresh?' do
    let(:args) { { repo_id: 1, build_id: 2 } }
    subject { described_class.new(client, args, opts).fresh? }

    context 'when the cached build_id is newer than the given build_id' do
      before { client.set('state:1', '2:success') }
      it { should be true }
    end

    context 'when the cached build_id is older than the given build_id' do
      before { client.set('state:1', '1:success') }
      it { should be false }
    end

    context 'when not cached' do
      it { should be false }
    end
  end
end
