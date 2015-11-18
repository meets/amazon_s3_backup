
require 'azure'
require './lib/backup/base'

module Backup

  class Azure < Base

    # コンストラクタ
    def initialize
      config = Application.instance.azure_config

      ::Azure.storage_account_name = config["storage_account_name"]
      ::Azure.storage_access_key = config["storage_access_key"]
    end

    # コンテナ名
    def bucket_name
      Application.instance.bucket_name
    end

    # blob情報
    def blobs
      ::Azure.blobs
    end

    # 同名ファイルがアップロード済みであるかを確認
    def exists?(file)
      begin
        blobs.get_blob(self.bucket_name, file)
        return true
      rescue
        return false
      end
    end


    # バックアップ
    def backup

      Application.instance.backups.each do | config |

        # ファイル取得
        list = FileList.new(config['target'])

        # 該当するファイル無し
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

          upload_name = File.join(config['upload_dir'], File.basename(file))

          # 同名のファイルがあるかを確認
          if self.exists?(upload_name)

            # サイクルの設定を確認
            if config.key?('cycle') && config['cycle'] > 0

              # 旧ファイルをリネーム
              config['cycle'].step(1, -1) do |i|

                org_name = upload_name + (i-1 > 0 ? ".#{i-1}" : '')
                mv_name = upload_name + (i > 0 ? ".#{i}" : '')

                if self.exists?(org_name)
                  blobs.copy_blob(self.bucket_name, mv_name, self.bucket_name, org_name)
                end
              end
            end

          end

          #アップロード
          block_ids = []
          File.open(file, 'rb') do |f|
            i = 0

            loop do

              # 4MBずつ処理
              content = f.read(4 * 1024 * 1024)
              break if content.nil?

              # ブロックIDの生成
              i += 1
              block_id = "%07d"%[i]
              block_ids << [block_id]

              # ブロックのアップロード
              blobs.create_blob_block(self.bucket_name, upload_name, block_id, content)

            end

            # アップロードしたブロックのコミット
            blobs.commit_blob_blocks(self.bucket_name, upload_name, block_ids)

          end

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

      self.blobs.list_blobs(self.bucket_name).each do | obj |

        next unless backups.find { |item| obj.name.match(/#{item['upload_dir']}\//) }

        #サイズ前の空白コントロール
        name = obj.name
        if name.length < 40
          (40 - name.length).times { name = name+" " }
        else
          name = name + "\n"
          40.times { name = name+" " }
        end

        list.push({
          :key => obj.name,
          :name => name,
          :length => FilesizeUnitConvert.int2str(obj.properties[:content_length]),
          :date => DateTime.parse(obj.properties[:last_modified]),
          :content_length => obj.properties[:content_length]
        })
      end

      list
    end

  end
end

