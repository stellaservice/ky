module KY
  class DeployGeneration
    def initialize(proc_path, full_output_dir, project_name=nil, current_namespace=nil)
      @proc_commands = File.read(proc_path).split("\n")
                            .map {|line| line.split(':', 2) }
                            .map {|k, v| [k, ["/bin/bash","-c", v]] }
                            .to_h
      @full_output_dir = full_output_dir
      @project_name = project_name || KY.configuration[:project_name]
      @current_namespace = current_namespace || KY.configuration[:namespace]
      @deployment_yaml = read_deployment_yaml
    end

    def call
      to_h.each do |file_path, deploy_hash|
        File.write(file_path, deploy_hash.to_yaml)
      end
    end

    def to_h
      proc_commands.map do |id, command_array|
        ["#{full_output_dir}/#{id}.yml", template_hash(id, command_array)]
      end.to_h
    end

    private
    attr_reader :proc_commands, :full_output_dir, :project_name, :current_namespace, :deployment_yaml

    def read_deployment_yaml
      if KY.configuration['deployment']
        File.read(KY.configuration['deployment'])
      else
        File.read(default_deployment_template)
      end
    end

    def default_deployment_template
      "#{__dir__}/../../templates/deployment.yml"
    end

    def template_hash(id, command_array)
      app_name =  KY.configuration['app_name'] || "#{project_name}-#{id}"
      template_context = Template.context(app_name: app_name, id: id, command_array: command_array)
      YAML.load(ERB.new(deployment_yaml).result(template_context))
    end
  end
end