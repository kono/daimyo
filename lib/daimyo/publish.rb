require 'daimyo'
# open3が必要なのはdiffy(本家もプルリクが出ててmerge待ち https://github.com/samg/diffy/pull/120)
# windows環境特有。
# Open3.capture3でdiffを呼ぶのでpathの通ったところにdiff.exeが必要。
require 'open3'

module Daimyo
  class Publish < Client
    include Daimyo::Helper

    def initialize(params = nil)
      @wiki ||= Daimyo::Client.new
      @is_local = params[:local] unless params.nil?
    end

    def search_files(project_id)
      space = @wiki.instance_variable_get(:@client).instance_variable_get(:@space_id)
      paths = Dir.glob(space + '/' + project_id  + '/**/*')

      diffy_paths = []
      paths.each do |path|
        diffy_path = []  
        if path.include?('.md')
          path_array = path.split('/')
          original_file_path = '.' + path_array[-1]
          path_array.pop
          original_path = path_array.join('/') + '/' + original_file_path
          diffy_path << original_path
        else
          diffy_path << path
        end
        diffy_path << path
        diffy_paths << diffy_path
      end
      diffy_paths
    end

    def read_file(path)
      File.open(path, 'r') do |file|
        file.read
      end
    end

    def run(project_id, dry_run)
      files = search_files(project_id)

      diff_files = []
      files.each do |file|
        if file[0].include?('.md')
          original = read_file(file[0]) 
          latest = read_file(file[1])
          diff_file = []
          if original != latest
            diff_file << file[1]
            diff_file << original
            diff_file << latest
            diff_files << diff_file
          end
        end
      end

      diff_files.each do |diff_file|
        puts diff_print_header(diff_file[0], @is_local)
        path_array = diff_file[0].split('/')
        wiki_id = path_array[-1].split('_')[0]

        if @is_local
          puts Diffy::Diff.new(diff_file[1], diff_file[2],
                               :include_diff_info => false, :context => 1).to_s(:color)
  
        else
          wiki_content = @wiki.export(wiki_id).body.content.gsub("\r\n", "\n")
          puts Diffy::Diff.new(wiki_content, diff_file[2],
                               :include_diff_info => false, :context => 1).to_s(:color)
        end

        # Todo: このへん直す！
        path_array.shift
        path_array.shift
        wiki_name = path_array[-1].split('_')[1].gsub(/.md/, '')
        # Todo: このへん直す！
        path_array.pop
        if path_array.length > 0
          wiki_name = path_array.join('/') + '/' + wiki_name
        else
          wiki_name
        end
        @wiki.publish(wiki_id, wiki_name, diff_file[2]) if dry_run.nil?
      end
    end
  end
end
