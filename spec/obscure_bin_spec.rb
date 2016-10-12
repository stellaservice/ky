require 'obscure_yaml/cli'
describe "works with stdout" do
  it "decodes" do
    output = File.read('spec/support/decoded.yml')
    expect($stdout).to receive(:<<).with(output)
    ObscureYaml::Cli.parse(["decode", "spec/support/encoded.yml"])
  end

  it "encodes" do
    output = File.read('spec/support/encoded.yml')
    expect($stdout).to receive(:<<).with(output)
    ObscureYaml::Cli.parse(["encode", "spec/support/decoded.yml"])
  end
end

describe "works with files" do
  let(:tmpfile_path) { "spec/support/tmpfile.yml" }
  it "decodes" do
    output = File.read('spec/support/decoded.yml')
    ObscureYaml::Cli.parse(["decode", "spec/support/encoded.yml", tmpfile_path])
    expect(File.read(tmpfile_path)).to eq(output)
    `rm #{tmpfile_path}`
  end

  it "encodes" do
    output = File.read('spec/support/encoded.yml')
    ObscureYaml::Cli.parse(["encode", "spec/support/decoded.yml", tmpfile_path])
    expect(File.read(tmpfile_path)).to eq(output)
    `rm #{tmpfile_path}`
  end
end

describe "merges yml files" do
  it "to stdout" do
    output = File.read('spec/support/web-merged.yml')
    expect($stdout).to receive(:<<).with(output)
    ObscureYaml::Cli.parse(["merge", 'spec/support/web-base.yml', 'spec/support/web-env.yml'])
  end
end

