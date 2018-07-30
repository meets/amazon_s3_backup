
require 'singleton'
require 'hipchat-api'
require 'mail'
require 'deep_hash_transform'
require './lib/backup/aws'
require './lib/backup/azure'

require 'net/http'
require 'uri'
require 'json'


class Application
  include Singleton

  # コンストラクタ
  def initialize
    init
  end

  # バックアップサービスの取得
  def service
    service_name = @config["service_name"]
    service_name ||= "aws"
    self.send(service_name)
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

  #slack連携
  def slack_message(message)
    return if @config['slack'].nil?

    uri  = URI.parse(@config['slack']['webhook'])
    params = {
      channel: @config['slack']['channel'],
      text: message,
    }
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.start do
      request = Net::HTTP::Post.new(uri.path)
      request.set_form_data(payload: params.to_json)
      http.request(request)
    end
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
