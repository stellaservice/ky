require 'ky/cli'
describe "cli commands" do
  let(:tmpfile_path) { "spec/support/tmpfile.yml" }
  before do # for backwards compatible with old non-inlining test/support behavior
    normal_config = KY::DEFAULT_CONFIG
    KY.define_methods_from_config(normal_config)
    allow(KY).to receive(:configuration).and_return(normal_config.merge(inline_config: false))
  end

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

  describe "compiles Procfile and env secrets/configs into entire deployments" do
    let(:tmpdir) { 'spec/support/tmpdir' }
    it "to directory" do
      KY::Cli.new.compile('spec/support/Procfile', 'spec/support/config.yml', 'spec/support/decoded.yml', tmpdir)
      expect(File.exists?("#{tmpdir}/web.yml")).to be true
      expect(File.exists?("#{tmpdir}/worker.yml")).to be true
      expect(File.exists?("#{tmpdir}/jobs.yml")).to be true
      `rm -r #{tmpdir}`
    end
  end

end

