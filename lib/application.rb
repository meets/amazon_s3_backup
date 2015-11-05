
require 'singleton'
require 'hipchat-api'
require 'mail'
require 'deep_hash_transform'
require './lib/backup/aws'
require './lib/backup/azure'


class Application
  include Singleton

  # コンストラクタ
  def initialize
    init
  end

  # バックアップサービスの取得
  def service
    self.send(@config["service_name"])
  end

  #設定を初期化する
  def init
    read_config
  end

  # Amazon S3接続用の設定を取得
  def aws_config
    config_file = File.join(root_path, 'config/aws.yml')
    YAML.load(File.read(config_file))
  end

  # AzureStorage接続用の設定を取得
  def azure_config
    config_file = File.join(root_path, 'config/azure.yml')
    YAML.load(File.read(config_file))
  end

  # AmazonS3バックアップ用のサービス
  def aws
    Backup::Aws.new
  end

  # Azureバックアップ用のサービス
  def azure
    Backup::Azure.new
  end


  # アプリケーションのルートパスを取得する
  # @return String
  def root_path
    File.dirname(File.dirname(__FILE__))
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

  # メール送信
  def sendmail(message)
    return if @config['mail'].nil?

    mail_settings = @config['mail']

    mail = Mail.new do
      from    mail_settings['from']
      to      mail_settings['to']
      subject mail_settings['subject']
      body    message
    end

    mail.delivery_method(:smtp, mail_settings['smtp'].symbolize_keys)
    mail.deliver!
  end

  private

    # アプリケーション設定を呼び出し
    def read_config

      #バックアップ用の設定読み込み
      config_file = File.join(root_path, 'config/application.yml')
      @config = YAML.load(File.read(config_file))

    end


end
