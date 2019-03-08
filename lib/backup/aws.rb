
require 'aws-sdk'
require './lib/backup/base'
require "pry"

module Backup
  class Aws < Base

    # バケット
    attr_accessor :bucket

    # コンストラクタ
    def initialize
      ::Aws.config.update({
        region: Application.instance.aws_config["region"],
        credentials: ::Aws::Credentials.new(Application.instance.aws_config["access_key_id"], Application.instance.aws_config["secret_access_key"])
      })

      s3 = ::Aws::S3::Resource.new
      @bucket = s3.bucket(Application.instance.bucket_name)
    end

    # 同名ファイルがアップロード済みであるかを確認
    def exists?(file)
      @bucket.object(file).exists?
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
                  @bucket.object(org_name).move_to( @bucket.object(mv_name) )
                end
              end
            end

          end

          #アップロード
          obj = @bucket.object(upload_name)
          obj.upload_file(file,
            :server_side_encryption => 'AES256',
            :metadata => { 'created_date' => Time.now.strftime('%Y-%m-%d') }
          )

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

      @bucket.objects.each do | summary |

        obj = @bucket.object(summary.key)

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
          :date => (obj.metadata['created_date'] ? obj.metadata['created_date'] : obj.last_modified.strftime('%Y-%m-%d')),
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

