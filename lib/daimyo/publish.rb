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
      paths = Dir.glob("#{@wiki.space_id}/#{project_id}/**/*")

      diffy_paths = []
      paths.each do |path|
        diffy_path = []  
        if path.include?('.md')
          # original_pathはドットで始まるファイル名.
          # "#{File.dirname(path)}/.#{File.basename(path)}"は元のoriginal_path
          diffy_path << "#{File.dirname(path)}/.#{File.basename(path)}"
        else
          diffy_path << path  # たぶんここ通らない
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

    def create_diff_files(files)
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
      diff_files
    end

    def run(project_id, dry_run)
      files = search_files(project_id)

      diff_files = create_diff_files(files)

      diff_files.each do |diff_file|
        puts diff_print_header(diff_file[0], @is_local)
        # diff_file[0]がアップロードするファイル
        regexp=/(?<wiki_no>[0-9]*)_(?<wiki_title>.*)\.md/
        matchdata = File.basename(diff_file[0]).match(regexp)
        wiki_id = matchdata[:wiki_no]
        wiki_name = matchdata[:wiki_title]

        if @is_local
          puts "### @is_local true"
          puts Diffy::Diff.new(diff_file[1], diff_file[2],
                               :include_diff_info => false, :context => 1).to_s(:color)
        else
          puts "### @is_local FALSE"
          wiki_content = @wiki.export(wiki_id).body.content.gsub("\r\n", "\n")
          puts Diffy::Diff.new(wiki_content, diff_file[2],
                               :include_diff_info => false, :context => 1).to_s(:color)
        end

        @wiki.publish(wiki_id, wiki_name, diff_file[2]) if dry_run.nil?
      end
    end
  end
end
