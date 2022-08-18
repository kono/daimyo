require 'daimyo'
require 'time'

module Daimyo
  class List
    include Daimyo::Helper

    def initialize
      @wiki ||= Daimyo::Client.new
    end

    def get_original_mtime(project_id, wiki)
      path = "./#{@wiki.space_id}/#{project_id}/\.#{wiki.id}_#{wiki.name}\.md"
      File.exists?(path) ? File.mtime(path) : nil
    end

    def run(project_id)
      wikis = []
      res = @wiki.list(project_id)
      res.body.each do |w|
        updated = Time.parse(w.updated).getlocal
        original_mtime = get_original_mtime(project_id, w)
        mark =''
        mark = '*' if updated.to_s > original_mtime.to_s
        wiki = []
        wiki << mark
        wiki << w.id
        wiki << w.name
        # wiki << Time.parse(w.created).getlocal
        wiki << updated
        wiki << original_mtime
        wikis << wiki
      end

      output_table(wikis)
    end

    def output_table(wikis)
      table = Terminal::Table.new(:headings => ['R',
                                                'ID',
                                                'Name',
                                                # 'Created',
                                                'Updated on Web',
                                                'Downloaded to Local'],
                                  :rows => wikis)
      puts table
    end
  end
end
