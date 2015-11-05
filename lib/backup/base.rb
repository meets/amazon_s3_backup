
require 'pry'

module Backup

  class Base

    # バックアップ対象情報
    def backups
      Application.instance.backups
    end

    # バックアップレポートの作成
    def report
      @hostname = `hostname`.chop
      @bucket_name = Application.instance.bucket_name

      @list = uploaded_files
      @total = @list.inject(0) { |sum, item| sum + item[:content_length] }

      @total = FilesizeUnitConvert.int2str(@total)

      #本文
      open(File.join(Application.instance.root_path, 'mail/report.erb')) do |f|
        erb = ERB.new(f.read, nil, '-')
        result = erb.result(binding)
        puts result

        Application.instance.hipchat_message(result)
        Rake::Task['sendmail'].execute(:message => result)
      end
    end
  end

end
