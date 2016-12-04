require 'yaml'
require 'base64'
require 'open-uri'
require 'fileutils'
require 'pathname'
require 'random_username'
require_relative 'ky/configuration'
require_relative 'ky/compilation'
require_relative 'ky/manipulation'
require_relative 'ky/env_generation'
require_relative 'ky/template'
require_relative 'ky/deploy_generation'
require_relative 'ky/hash'


module KY
  CONFIG_FILE_NAMES = [".ky.yml", ".ky.yaml", "Lubefile"]
  CONFIG_LOCATIONS = ["#{Dir.pwd}/", "#{Dir.home}/"]
  DEFAULT_CONFIG = {
    environments: [],
    replica_count: 1,
    image_pull_policy: "Always",
    namespace: "default",
    image: "<YOUR_DOCKER_IMAGE>",
    image_tag: "latest",
    api_version: "extensions/v1beta1",
    inline_config: true,
    inline_secret: false,
    project_name: "global",
    force_configmap_apply: false
  }.with_indifferent_access

end