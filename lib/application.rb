
require 'singleton'
require 'hipchat-api'

class Application
  include Singleton

  # コンストラクタ
  def initialize
    init
  end


  #設定を初期化する
  def init
    init_aws
    read_config
  end


  # アプリケーションのルートパスを取得する
  # @return String
  def root_path
    File.dirname(File.dirname(__FILE__))
  end


  #バックアップ対象のバケットを取得
  def bucket
    if @bucket != nil
      return @bucket
    end

    #awsオブジェクトの作成
    s3 = AWS::S3.new
    @bucket = s3.buckets[@config['bucket_name']]
  end


  #バックアップ対象のリストを取得する
  def backups
    @config['backups']
  end

  #バックアップ名の取得
  def bucket_name
    @config['bucket_name']
  end

  #hipchat連携
  def hipchat_message(message)
    return if @config['hipchat'].nil?
    api = HipChat::API.new(@config['hipchat']['token'])
    api.rooms_message(@config['hipchat']['room_id'], "backup", message, 1, @config['hipchat']['color'], "text")
  end

  private

    # アプリケーション設定を呼び出し
    def read_config

      #バックアップ用の設定読み込み
      config_file = File.join(root_path, 'config/application.yml')
      @config = YAML.load(File.read(config_file))

    end


    # aws-sdkをセットアップ
    def init_aws

      #AWS-SDKの設定読み込み
      config_file = File.join(root_path, 'config/aws.yml')
      config = YAML.load(File.read(config_file))
      AWS.config(config)
    end

end
