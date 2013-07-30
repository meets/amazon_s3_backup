# coding: utf-8

require 'rubygems'
require 'yaml'
require 'aws-sdk'
require 'digest/md5'
require 's3etag'
require './lib/application'



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
          puts "Skip same file \"#{file}\"."
          next
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
        :server_side_encryption => :aes256)

      #ファイルの削除
      if b.key?('delete?') && b['delete?'].kind_of?(TrueClass)
        File.delete(file)
      end
    end


  end

end

