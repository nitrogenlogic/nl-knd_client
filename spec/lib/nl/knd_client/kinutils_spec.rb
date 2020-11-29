RSpec.describe(NL::KndClient::Kinutils) do
  describe 'String#kin_kvp' do
    it 'can parse simple key-value pairs with unquoted strings' do
      expect('a=b c=d'.kin_kvp).to eq({ 'a' => 'b', 'c' => 'd' })
    end

    it 'ignores non-key-value-pair text' do
      expect('a=b c = d e= f g =h i=" j"'.kin_kvp).to eq({ 'a' => 'b', 'i' => ' j' })
    end

    it 'handles quoted keys and quoted values).to eq( ignoring invalid quoted pairs' do
      expect('"a="b "c="="=d" e"=f"'.kin_kvp).to eq({ 'c=' => '=d', 'e"' => 'f"' })
    end

    it 'can parse strings' do
      expect('a=""'.kin_kvp).to eq({ 'a' => '' })
      expect('a="'.kin_kvp).to eq({ 'a' => '' })
      expect('a="\\x20"'.kin_kvp).to eq({ 'a' => ' ' })
      expect('a="\\x20'.kin_kvp).to eq({ 'a' => ' ' })
      expect('a=\\x20'.kin_kvp).to eq({ 'a' => '\\x20' })
      expect('a=b'.kin_kvp).to eq({ 'a' => 'b' })
      expect('"a"="b"'.kin_kvp).to eq({ 'a' => 'b' })
      expect('"a"=b'.kin_kvp).to eq({ 'a' => 'b' })
      expect('"a"="b'.kin_kvp).to eq({ 'a' => 'b' })
      expect('a="b"'.kin_kvp).to eq({ 'a' => 'b' })
    end

    it 'parses solitary numeric punctuation as a string' do
      expect('a=.'.kin_kvp).to eq({ 'a' => '.' })
      expect('a=+'.kin_kvp).to eq({ 'a' => '+' })
      expect('a=-'.kin_kvp).to eq({ 'a' => '-' })
    end

    it 'can parse integers' do
      expect('a=5'.kin_kvp).to eq({ 'a' => 5 })
      expect('a=0'.kin_kvp).to eq({ 'a' => 0 })
      expect('a=-5'.kin_kvp).to eq({ 'a' => -5 })
      expect('a=-0'.kin_kvp).to eq({ 'a' => 0 })
      expect('a=+3'.kin_kvp).to eq({ 'a' => 3 })
    end

    it 'can parse floats' do
      expect('a=1.5'.kin_kvp).to eq({ 'a' => 1.5 })
      expect('a=-1.5'.kin_kvp).to eq({ 'a' => -1.5 })
      expect('a=.25'.kin_kvp).to eq({ 'a' => 0.25 })
      expect('a=0.'.kin_kvp).to eq({ 'a' => 0.0 })
      expect('a=-5.'.kin_kvp).to eq({ 'a' => -5.0 })
    end

    it 'can parse exponential notation' do
      expect('a=1e5'.kin_kvp).to eq({ 'a' => 1e5 })
      expect('a=1.1e5'.kin_kvp).to eq({ 'a' => 1.1e5 })
      expect('a=-3E5'.kin_kvp).to eq({ 'a' => -3e5 })
      expect('a=-3.0E5'.kin_kvp).to eq({ 'a' => -3e5 })
      expect('a=+3e+5'.kin_kvp).to eq({ 'a' => 3.0E5 })

    end

    it 'does not parse quoted strings as numbers' do
      expect('a="5"'.kin_kvp).to eq({ 'a' => '5' })
    end

    it 'parses invalid numeric lookalikes as strings' do
      expect('a=-3E5.0'.kin_kvp).to eq({ 'a' => '-3E5.0' })
      expect('a=+3e+'.kin_kvp).to eq({ 'a' => '+3e+' })
      expect('a=+3e'.kin_kvp).to eq({ 'a' => '+3e' })
      expect('a=+e'.kin_kvp).to eq({ 'a' => '+e' })
      expect('a=-e3'.kin_kvp).to eq({ 'a' => '-e3' })
      expect('a=-3.e1'.kin_kvp).to eq({ 'a' => '-3.e1' })
      expect('a=-3.e.1'.kin_kvp).to eq({ 'a' => '-3.e.1' })
      expect('a=1.e0'.kin_kvp).to eq({ 'a' => '1.e0' })
    end

    it 'uses symbols for keys when :symbolize_keys is true' do
      expect('a=1 b=two c=3.125'.kin_kvp(symbolize_keys: true)).to eq({ a: 1, b: 'two', c: 3.125 })
    end

    it 'raises an error if something other than an options hash is passed as a parameter' do
      expect { 'a=1'.kin_kvp('not a hash') }.to raise_error(ArgumentError)
    end
  end

  describe 'String#kin_unescape' do
    pending
  end

  describe 'String#kin_unescape!' do
    pending
  end

  describe '.unpack11_to_16' do
    pending
  end

  describe '.plot_linear' do
    pending
  end

  describe '.plot_overhead' do
    pending
  end

  describe '.plot_side' do
    pending
  end

  describe '.plot_front' do
    pending
  end
end
