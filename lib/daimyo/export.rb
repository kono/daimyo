require 'daimyo'

module Daimyo
  class Export
    include Daimyo::Helper

    def initialize
      @wiki ||= Daimyo::Client.new
    end

    def run(project_id, wiki_id = nil, force)
      ids = select_wiki_ids(project_id)
      pb = ProgressBar.create(:format => "%a %b\u{15E7}%i %p%% %t",
                              :progress_mark => ' ',
                              :remainder_mark => "\u{FF65}",
                              :starting_at => 10,
                              :length => 50)
      ids.each do |id|
        wiki = @wiki.export(id).body
        name = wiki.name
        content = wiki.content
        write_file(project_id, id, name, content, force)
        pb.increment
        sleep 0.1
      end
      pb.finish
    end

    private

    def select_wiki_ids(project_id)
      @wiki.list(project_id).body.map { |w| w.id }
    end

    def write_file(project_id, id, name, content, force)
      file_path = get_md_path(@wiki, project_id, id, name)
      original_file_path = get_original_path(@wiki, project_id, id, name)
      create_wiki_directory(File.dirname(file_path))

      original_file_mtime =  get_mtime(original_file_path)
      if (get_mtime(file_path).to_s > original_file_mtime.to_s) and !force
        puts "#{file_path}はダウンロード後更新されているのでExportしません。"
        puts "--forceで実行すれば強制的にExportします。"
      else
        File.open(file_path, 'w') do |f|
          f.puts(content.gsub("\r\n", "\n"))
        end

        File.open(original_file_path, 'w') do |f|
          f.puts(content.gsub("\r\n", "\n"))
        end
      end
    end

    def create_wiki_directory(path)
      FileUtils.mkdir_p(path) unless FileTest.exist?(path)
      path
    end

    def define_directory_path(project_id, name)
      space = @wiki.instance_variable_get(:@client).instance_variable_get(:@space_id)
      return space + '/' + project_id unless name.include?('/')
      space + '/' + project_id + '/' + File.dirname(name) # 最後の 1 要素をファイル名とする
    end

    def define_file_path(name)
      return name unless name.include?('/')
      File.basename(name) # 最後の 1 要素をファイル名とする
    end

  end
end
