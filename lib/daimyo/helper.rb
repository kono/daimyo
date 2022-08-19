module Daimyo
  module Helper
    def diff_print_header(message, is_local)
      return "\e[43m" + message + "\e[0m" unless is_local
      "\e[41m" + message + "\e[0m"
    end

    # 編集対象でない、ファイル名に.がついているファイルのpath
    def get_original_path(client, project_id, wiki_id, wiki_name)
      "./#{client.space_id}/#{project_id}/\.#{wiki_id}_#{wiki_name}\.md"
    end

    # 編集対象のファイルのpath
    def get_md_path(client, project_id, wiki_id, wiki_name)
      "./#{client.space_id}/#{project_id}/#{wiki_id}_#{wiki_name}\.md"
    end

    def get_mtime(path)
      File.exists?(path) ? File.mtime(path) : nil
    end



  end
end
