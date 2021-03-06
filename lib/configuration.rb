#!/usr/bin/ruby
##########################################################################
# Copyright 2016 ThoughtWorks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

RELEASES_JSON_URL = 'https://download.gocd.io/experimental/releases.json'

def env(variable, default=nil)
  default = yield if block_given?
  ENV[variable] || default
end

module Configuration
  # Setup configuration
  class SetUp
    def pipelines
      (1..number_of_pipelines.to_i).map { |i| "gocd.perf#{i}" }
    end

    def agents
      (1..env('NO_OF_AGENTS', 10).to_i).map { |i| "agent-#{i}" }
    end

    def thread_groups
      (1..env('NO_OF_THREAD_GROUPS', 10).to_i).to_a
    end

    def load_test_duration
      env('LOAD_TEST_DURATION', '600').to_i
    end

    def git_repository_host
      env('GIT_REPOSITORY_HOST', 'git://localhost')
    end

    def server_install_dir
      Pathname.new(env('SERVER_INSTALL_DIR', '.')) + 'go-server'
    end

    def agents_install_dir
      Pathname.new(env('AGENTS_INSTALL_DIR', '.')) + 'go-agents'
    end

    def include_plugins?
      env('INCLUDE_PLUGINS')=='Y'
    end

    def plugin_src_dir
      Pathname.new(env('PLUGIN_SRC_DIR', ''))
    end

    def tools_dir
      Pathname.new(env('TOOLS_DIR', './tools'))
    end

    def jmeter_dir
      tools_dir + 'apache-jmeter-3.0'
    end

    def jmeter_bin
      jmeter_dir + 'bin/'
    end

    def tee_dir
      Pathname.new(Dir.pwd+'/tools/TEE-CLC-14.0.3')
    end

    def download_url
      env('DOWNLOAD_URL', 'https://download.gocd.io/experimental')
    end

    def go_version
      raw_version = env('GO_VERSION') do
          json = JSON.parse(open(RELEASES_JSON_URL).read)
          json.sort {|a, b| a['go_full_version'] <=> b['go_full_version']}.last['go_full_version']
      end

      unless raw_version.include? '-'
        raise 'Wrong GO_VERSION format use 16.X.X-xxxx'
      end

      raw_version.split '-'
    end

    def config_save_duration
      {
        interval: env('CONFIG_SAVE_INTERVAL', 20).to_i,
        times: env('NUMBER_OF_CONFIG_SAVES', 30).to_i
      }
    end

    def git_root
      env('GIT_ROOT', 'gitrepos')
    end

    def git_repos
      pipelines.map { |i| "#{git_root}/git-repo-#{i}" }
    end

    def git_commit_duration
      {
        interval: env('GIT_COMMIT_INTERVAL', 5).to_i,
        times: env('NUMBER_OF_COMMITS', 30).to_i
      }
    end

    def tfs_commit_duration
      {
        interval: env('TFS_COMMIT_INTERVAL', 60).to_i,
        times: env('NUMBER_OF_TFS_COMMITS', 2).to_i
      }
    end

    def tee_path
      tee_dir + "tf"
    end

    def tfs_user
        env('TFS_USER', 'go.tfs.user@gmail.com')
    end

    def tfs_pwd
      pwd = env('TFS_PWD', nil)
      raise 'Missing TFS_PWD environment variable' unless pwd
      pwd
    end

    def tfs_url
      env('TFS_URL', 'https://go-tfs-user.visualstudio.com')
    end

    def materials_ratio
      {
        git: env('GIT_MATERIAL_RATIO', 90).to_i,
        tfs: env('TFS_MATERIAL_RATIO', 10).to_i
      }
    end


    private

    def number_of_pipelines
      env('NO_OF_PIPELINES', 10)
    end
  end

  # Setup configuration
  class Configuration
    def releases_json
      'https://download.gocd.io/experimental/releases.json'
    end

    def config_update_interval
      env('CONFIG_UPDATE_INTERVAL', 5)
    end

    def scm_commit_interval
      env('SCM_UPDATE_INTERVAL', 5)
    end

    def server_dir
      env('SERVER_DIR', '/tmp')
    end

    def gocd_host
      "#{server_url}/go"
    end
  end

  # Go server configuration
  class Server
    def auth
      env('AUTH', nil)
    end

    def host
      env('GOCD_HOST', '127.0.0.1')
    end

    def port
      env('GO_SERVER_PORT', '8153')
    end

    def secure_port
      env('GO_SERVER_SSL_PORT', '8154')
    end

    def base_url
      "http://#{auth ? (auth + '@') : ''}#{host}:#{port}"
    end

    def url
      "#{base_url}/go"
    end

    def secure_url
      env('PERF_SERVER_SSH_URL', 'https://localhost:8154')
    end

    def environment
      {
        'GO_SERVER_SYSTEM_PROPERTIES' => env('GO_SERVER_SYSTEM_PROPERTIES', ''),
        'GO_SERVER_PORT' => port,
        'GO_SERVER_SSL_PORT' => secure_port,
        'SERVER_MEM' => env('SERVER_MEM', '6g'),
        'SERVER_MAX_MEM' => env('SERVER_MAX_MEM', '8g')
      }
    end
  end
end
