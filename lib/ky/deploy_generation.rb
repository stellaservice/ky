module KY
  class DeployGeneration
    API_VERSION = "extensions/v1beta1"
    IMAGE_TYPE  = "docker/image"
    DEFAULT_PULL_POLICY = "Always"
    DEFAULT_PROJECT_NAME = "global"
    DEFAULT_NAMESPACE = "default"
    DEFAULT_REPLICA_COUNT = 1

    #string array meta-trick to avoid naked strings everywhere below, yaml doesn't to_s symbols as desired
    %w(apiVersion Deployment imagePullPolicy namespace command
       replicas template labels app kind containers image
       data metadata name key valueFrom spec template containers env).each do |raw_string|
      define_method(raw_string.underscore) { raw_string }
    end

    def initialize(proc_path, output_dir, project_name=DEFAULT_PROJECT_NAME, current_namespace=DEFAULT_NAMESPACE)
      @proc_commands = File.read(proc_path).split("\n")
                            .map {|line| line.split(':', 2) }
                            .map {|k, v| [k, ["/bin/bash","-c", v]] }
                            .to_h
      @output_dir = output_dir
      @project = project_name
      @current_namespace = current_namespace
    end

    def call
      to_h.each do |file_path, deploy_hash|
        File.write(file_path, deploy_hash.to_yaml)
      end
    end

    def to_h
      proc_commands.map do |id, command_array|
        ["#{output_dir}/#{id}.yml", template_hash(id, command_array)]
      end.to_h
    end

    private
    attr_reader :proc_commands, :output_dir, :project, :current_namespace

    def template_hash(id, command_array)
      {api_version => API_VERSION,
       kind => deployment,
       metadata =>{ name => id, namespace => current_namespace},
       spec =>
        {replicas => replica_count,
         template =>
          {
            metadata => {
              labels =>{ app =>"#{project}-#{id}"}
             },
           spec => {
            containers =>
              [
                {
                 name => id,
                 image => IMAGE_TYPE,
                 image_pull_policy => pull_policy,
                 command => command_array
                }
              ]
            }
          }
        }
      }
    end

    def replica_count
      ENV['REPLICA_COUNT'] || DEFAULT_REPLICA_COUNT
    end

    def pull_policy
      ENV['PULL_POLICY'] || DEFAULT_PULL_POLICY
    end

  end
end