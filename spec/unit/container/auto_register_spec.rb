require 'dry/system/container'

RSpec.describe Dry::System::Container, '.auto_register!' do
  context 'standard loader' do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures').realpath
        end

        load_paths!('components')
        auto_register!('components')
      end
    end

    it { expect(Test::Container['foo']).to be_an_instance_of(Foo) }
    it { expect(Test::Container['bar']).to be_an_instance_of(Bar) }
    it { expect(Test::Container['bar.baz']).to be_an_instance_of(Bar::Baz) }
  end

  context 'with custom registration block' do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures').realpath
        end

        load_paths!('components')
      end
    end

    it 'yields found components' do
      Test::Container.auto_register!('components') do |component|
        component.identifier
      end

      expect(Test::Container['foo']).to eql('foo')
      expect(Test::Container['bar']).to eql('bar')
      expect(Test::Container['bar.baz']).to eql('bar.baz')
    end
  end

  context 'standard loader with a default namespace configured' do
    before do
      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures').realpath
          config.default_namespace = 'namespaced'
        end

        load_paths!('namespaced_components')
        auto_register!('namespaced_components')
      end
    end

    specify { expect(Test::Container['bar']).to be_a(Namespaced::Bar) }
    specify { expect(Test::Container['bar'].foo).to be_a(Namespaced::Foo) }
    specify { expect(Test::Container['foo']).to be_a(Namespaced::Foo) }
  end

  context 'with a custom loader' do
    before do
      class Test::Loader < Dry::System::Loader
        def call(*args)
          constant.respond_to?(:call) ? constant : constant.new(*args)
        end
      end

      class Test::Container < Dry::System::Container
        configure do |config|
          config.root = SPEC_ROOT.join('fixtures').realpath
          config.loader = ::Test::Loader
        end

        load_paths!('components')
        auto_register!('components')
      end
    end

    it { expect(Test::Container['foo']).to be_an_instance_of(Foo) }
    it { expect(Test::Container['bar']).to eq(Bar) }
    it { expect(Test::Container['bar'].call).to eq("Welcome to my Moe's Tavern!") }
    it { expect(Test::Container['bar.baz']).to be_an_instance_of(Bar::Baz) }
  end
end
