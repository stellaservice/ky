require 'ky/cli'
describe "ky cli" do
  describe "legacy/component cli commands" do
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

  describe "primary cli command generates and" do
    let(:instance) { KY.new }
    let(:fake_tag) { 'fake_tag' }
    let(:tmpdir) { 'spec/support/tmpdir' }
    after { `rm -r #{tmpdir}` }
    describe "compiles Procfile and env secrets/configs into entire deployments" do
      it "to directory" do
        instance = KY::Cli.new
        instance.options = {procfile_path: 'spec/support/Procfile'}
        instance.compile('spec/support/config.yml', 'spec/support/decoded.yml', tmpdir)
        expect(File.exists?("#{tmpdir}/web.deployment.yml")).to be true
        expect(File.exists?("#{tmpdir}/worker.deployment.yml")).to be true
        expect(File.exists?("#{tmpdir}/jobs.deployment.yml")).to be true
      end
    end

    describe "encodes secrets.yml when compiling from Procfile without image_tag" do
      it "to directory" do
        instance = KY::Cli.new
        instance.options = {procfile_path: 'spec/support/Procfile'}
        instance.compile('spec/support/config.yml', 'spec/support/decoded.yml', tmpdir)
        expect(File.exists?("#{tmpdir}/global.secret.yml")).to be true
        YAML.load(File.read("#{tmpdir}/global.secret.yml"))['data'].each do |_k, v|
          expect(v).to match(KY::Manipulation::BASE_64_DETECTION_REGEX)
        end
      end
    end

    describe "encodes secrets.yml when compiling from Procfile with image_tag" do
      it "to directory" do
        instance = KY::Cli.new
        instance.options = {image_tag: fake_tag, procfile_path: 'spec/support/Procfile'}
        instance.compile('spec/support/config.yml', 'spec/support/decoded.yml', tmpdir)
        expect(File.exists?("#{tmpdir}/global.secret.yml")).to be true
        YAML.load(File.read("#{tmpdir}/global.secret.yml"))['data'].each do |_k, v|
          expect(v).to match(KY::Manipulation::BASE_64_DETECTION_REGEX)
        end
      end
    end

    describe "uses image_tag when passed in as option" do
      it "to directory" do
        instance = KY::Cli.new
        instance.options = {image_tag: fake_tag, procfile_path: 'spec/support/Procfile'}
        instance.compile('spec/support/config.yml', 'spec/support/decoded.yml', tmpdir)
        expect(File.exists?("#{tmpdir}/web.deployment.yml")).to be true
        expect(File.read("#{tmpdir}/web.deployment.yml")).to match(fake_tag)
      end
    end

    describe "uses namespace when passed in as option" do
      it "to directory" do
        instance = KY::Cli.new
        instance.options = {namespace: fake_tag, procfile_path: 'spec/support/Procfile'}
        instance.compile('spec/support/config.yml', 'spec/support/decoded.yml', tmpdir)
        expect(File.exists?("#{tmpdir}/web.deployment.yml")).to be true
        expect(File.read("#{tmpdir}/web.deployment.yml")).to match(fake_tag)
      end
    end

    describe "merges yaml to named ids templates when compiling" do
      before { `cp spec/support/Lubefile .`}
      after { `rm Lubefile` }
      it "to directory" do
        instance = KY::Cli.new
        instance.options = {procfile_path: 'spec/support/Procfile'}
        instance.compile('spec/support/config.yml', 'spec/support/decoded.yml', tmpdir)
        expect(File.exists?("#{tmpdir}/web.deployment.yml")).to be true
        expect(File.exists?("#{tmpdir}/jobs.deployment.yml")).to be true
        expect(File.read("#{tmpdir}/web.deployment.yml")).to match('port')
        expect(File.read("#{tmpdir}/jobs.deployment.yml")).not_to match('port')
      end
    end

    describe "serializes yaml without reference to HashWithIndifferentAccess" do
      before { `cp spec/support/Lubefile .`}
      after { `rm Lubefile` }
      it "to directory" do
        instance = KY::Cli.new
        instance.compile('spec/support/config.yml', 'spec/support/decoded.yml', tmpdir)
        expect(File.exists?("#{tmpdir}/web.deployment.yml")).to be true
        expect(File.read("#{tmpdir}/web.deployment.yml")).not_to match('HashWithIndifferentAccess')
      end
    end

    describe "adds random inline value if force_configmap_apply is true" do
      before { `cp spec/support/Lubefile .`}
      after { `rm Lubefile` }
      it "to directory" do
        instance = KY::Cli.new
        instance.options = {procfile_path: 'spec/support/Procfile', force_configmap_apply: true}
        instance.compile('spec/support/config.yml', 'spec/support/decoded.yml', tmpdir)
        expect(File.exists?("#{tmpdir}/web.deployment.yml")).to be true
        expect(File.read("#{tmpdir}/web.deployment.yml")).to match('FORCE_CONFIGMAP_APPLY')
      end
    end

  end
end

