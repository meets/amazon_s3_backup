# coding: utf-8

require 'rubygems'
require 'yaml'
require 'aws-sdk'
require 'digest/md5'
require 's3etag'
require 'erb'
require './lib/application'
require './lib/filesize_unit_convert'



desc "バックアップを行うタスク"
task :backup do

  #バケットの取得
  bucket = Application.instance.bucket

  Application.instance.backups.each do | b |

    #ファイル取得
    list = FileList.new(b['target'])

    #該当するファイル無し
    if list.count < 1
      STDERR.puts "Target not match \"#{b['target']}\"."
      next
    end

    list.each do | file |

      #ファイル確認
      unless File.exists?(file)
        STDERR.puts "Invalid file \"#{file}\"."
        next
      end


      #アップロード後のファイル名を作成
      upload_name = File.join(b['upload_dir'], File.basename(file))


      #同名のファイルがあるかを確認
      if bucket.objects[upload_name].exists?

        #ファイルのハッシュ値を取得
        md5 = S3Etag.calc(:file => file);

        #ファイルのEtagからmd5ハッシュ値を取得して比較
        etag = bucket.objects[upload_name].etag
        if etag.match(md5)
#          puts "Skip same file \"#{file}\"."
#          next
        end

        #サイクルの設定を確認
        if b.key?('cycle') && b['cycle'] > 0

          #旧ファイルをリネーム
          b['cycle'].step(1, -1) do |i|

            org_name = upload_name + (i-1 > 0 ? ".#{i-1}" : '')
            mv_name = upload_name + (i > 0 ? ".#{i}" : '')

            if bucket.objects[org_name].exists?
              bucket.objects[org_name].move_to(mv_name)
            end
          end
        end

      end

      #アップロード
      bucket.objects.create(upload_name, Pathname.new(file),
        :server_side_encryption => :aes256,
        :metadata => { 'create_date' => Time.now.strftime('%Y-%m-%d') })

      #ファイルの削除
      if b.key?('delete?') && b['delete?'].kind_of?(TrueClass)
        File.delete(file)
      end
    end


  end

end




desc "レポートメール送信"
task :report do

  #バケットの取得
  bucket = Application.instance.bucket

  @total = 0

  @hostname = `hostname`.chop
  @bucket_name = Application.instance.bucket_name

  @list = []
  bucket.objects.each do | obj |

    # バックアップターゲット以外は無視
    if Application.instance.backups.find { |item| obj.key.match(/#{item['upload_dir']}\//) }

    length = obj.content_length
    @total = length + @total

    # printf("[%s]\n", obj.key)
    if obj.metadata['created_date']
      # p obj.metadata['created_date']
    end

    #サイズ前の空白コントロール
    name = obj.key
    if name.length < 40
      (40 - name.length).times { name = name+" " }
    else
      name = name + "\n"
      40.times { name = name+" " }
    end

    @list.push({
      :name => name,
      :length => FilesizeUnitConvert.int2str(length),
      :date => (obj.metadata['created_date'] ? obj.metadata['created_date'] : obj.last_modified).strftime('%Y-%m-%d')
    })

    end

  end

  @total = FilesizeUnitConvert.int2str(@total)

  #本文
  open(File.join(Application.instance.root_path, 'mail/report.erb')) do |f|
    erb = ERB.new(f.read, nil, '-')
    puts erb.result

    Application.instance.hipchat_message(erb.result)
    Rake::Task['sendmail'].execute(:message => erb.result)
  end

end



desc "レポートメール送信"
task :sendmail, :message do |task, args|
  Application.instance.sendmail(args[:message])
end


desc "管理下のファイルのダウンロード用URLを発行する"
task :download, :file do |task, args|
  # 5分間有効
  obj = Application.instance.bucket.objects[args[:file]]
  puts obj.url_for(:read, :expires => 5 * 60).to_s

end
