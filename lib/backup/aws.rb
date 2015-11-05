
require 'aws-sdk'
require './lib/backup/base'


module Backup
  class Aws < Base

    # バケット
    attr_accessor :bucket

    # コンストラクタ
    def initialize
      AWS.config(Application.instance.aws_config)

      s3 = AWS::S3.new
      @bucket = s3.buckets[Application.instance.bucket_name]
    end

    # 同名ファイルがアップロード済みであるかを確認
    def exists?(file)
      @bucket.objects[file].exists?
    end

    # バックアップ
    def backup

      Application.instance.backups.each do | config |

        #ファイル取得
        list = FileList.new(config['target'])

        #該当するファイル無し
        if list.count < 1
          STDERR.puts "Target not match \"#{config['target']}\"."
          next
        end

        list.each do | file |

          #ファイル確認
          unless File.exists?(file)
            STDERR.puts "Invalid file \"#{file}\"."
            next
          end


          #アップロード後のファイル名を作成
          upload_name = File.join(config['upload_dir'], File.basename(file))


          #同名のファイルがあるかを確認
          if self.exists?(upload_name)

            #サイクルの設定を確認
            if config.key?('cycle') && config['cycle'] > 0

              #旧ファイルをリネーム
              config['cycle'].step(1, -1) do |i|

                org_name = upload_name + (i-1 > 0 ? ".#{i-1}" : '')
                mv_name = upload_name + (i > 0 ? ".#{i}" : '')

                if self.exists?(org_name)
                  @bucket.objects[org_name].move_to(mv_name)
                end
              end
            end

          end

          #アップロード
          @bucket.objects.create(upload_name, Pathname.new(file),
            :server_side_encryption => :aes256,
            :metadata => { 'create_date' => Time.now.strftime('%Y-%m-%d') })

          #ファイルの削除
          if config.key?('delete?') && config['delete?'].kind_of?(TrueClass)
            File.delete(file)
          end
        end


      end

    end

    # アップロード済みのファイル情報を取得
    def uploaded_files
      list = []

      @bucket.objects.each do | obj |

        next unless backups.find { |item| obj.key.match(/#{item['upload_dir']}\//) }

        length = obj.content_length

        #サイズ前の空白コントロール
        name = obj.key
        if name.length < 40
          (40 - name.length).times { name = name+" " }
        else
          name = name + "\n"
          40.times { name = name+" " }
        end

        list.push({
          :key => obj.key,
          :name => name,
          :length => FilesizeUnitConvert.int2str(length),
          :date => (obj.metadata['created_date'] ? obj.metadata['created_date'] : obj.last_modified).strftime('%Y-%m-%d'),
          :content_length => obj.content_length
        })
      end

      list
    end

    # ダウンロード用のURLを発行する
    def download_url(file)

      # 5分間有効
      obj = @bucket.objects[file]
      obj.url_for(:read, :expires => 5 * 60).to_s
    end

  end
end

