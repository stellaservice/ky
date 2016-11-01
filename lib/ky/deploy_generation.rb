module KY
  class DeployGeneration
    def initialize(full_output_dir, project_name, configuration=Configuration.new)
      @configuration = configuration
      @proc_commands = File.read(configuration[:procfile_path]).split("\n")
                            .map {|line| line.split(':', 2) }
                            .map {|k, v| [k, ["/bin/bash","-c", v]] }
                            .to_h
      @full_output_dir = full_output_dir
      @project_name = project_name || configuration[:project_name]
      @deployment_yaml = read_deployment_yaml
    end

    def call
      to_h.each do |file_path, deploy_hash|
        File.write(file_path, deploy_hash.to_plain_yaml)
      end
    end

    def to_h
      proc_commands.map do |id, command_array|
        ["#{full_output_dir}/#{id}.deployment.yml", template_hash(id, command_array)]
      end.to_h
    end

    private
    attr_reader :proc_commands, :full_output_dir, :project_name, :deployment_yaml, :configuration

    def read_deployment_yaml
      if configuration['deployment']
        File.read(configuration['deployment'])
      else
        File.read(default_deployment_template)
      end
    end

    def default_deployment_template
      "#{__dir__}/../../templates/deployment.yml"
    end

    def template_hash(id, command_array)
      app_name =  configuration['app_name'] || "#{project_name}-#{id}"
      template_context = Template.new(configuration).context(app_name: app_name, id: id, command_array: command_array)
      tmp = Manipulation.merge_hash(
        YAML.load(
          ERB.new(deployment_yaml).result(template_context)
        ),
        deploy_merge(id)
      )
    end

    def deploy_merge(id)
      return {} unless configuration[:merge]
      configuration[:merge][id].to_h
    end
  end
end