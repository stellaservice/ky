require 'ky/cli'
describe "cli commands" do
  let(:tmpfile_path) { "spec/support/tmpfile.yml" }
  after { `rm #{tmpfile_path}` if File.exists?(tmpfile_path) }
  describe "works with stdout" do
    it "decodes" do
      output = File.read('spec/support/decoded.yml')
      expect($stdout).to receive(:<<).with(output)
      KY::Cli.new.decode("spec/support/encoded.yml")
    end

    it "encodes" do
      output = File.read('spec/support/encoded.yml')
      expect($stdout).to receive(:<<).with(output)
      KY::Cli.new.encode("spec/support/decoded.yml")
    end
  end

  describe "works with files" do
    it "decodes" do
      output = File.read('spec/support/decoded.yml')
      KY::Cli.new.decode("spec/support/encoded.yml", tmpfile_path)
      expect(File.read(tmpfile_path)).to eq(output)
    end

    it "encodes" do
      output = File.read('spec/support/encoded.yml')
      KY::Cli.new.encode("spec/support/decoded.yml", tmpfile_path)
      expect(File.read(tmpfile_path)).to eq(output)
    end
  end

  describe "merges yml files" do
    it "to stdout" do
      output = File.read('spec/support/web-merged.yml')
      expect($stdout).to receive(:<<).with(output)
      KY::Cli.new.merge('spec/support/web-base.yml', 'spec/support/web-env.yml')
    end
  end

  describe "generates env section" do
    it "to stdout" do
      output = File.read('spec/support/web-env.yml')
      expect($stdout).to receive(:<<).with(output)
      KY::Cli.new.env('spec/support/decoded.yml', 'spec/support/config.yml')
    end

    it "config and secret are order independent" do
      output = File.read('spec/support/web-env.yml')
      expect($stdout).to receive(:<<).with(output)
      KY::Cli.new.env('spec/support/config.yml', 'spec/support/decoded.yml')
    end

    it "to file" do
      output = File.read('spec/support/web-env.yml')
      KY::Cli.new.env('spec/support/config.yml', 'spec/support/decoded.yml', tmpfile_path)
      expect(File.read(tmpfile_path)).to eq(output)
    end
  end

end

