# coding: utf-8

require 'rubygems'
require 'yaml'
require 'digest/md5'
require 'erb'
require './lib/application'
require './lib/filesize_unit_convert'


desc "バックアップを行うタスク"
task :backup do

  service = Application.instance.service
  service.backup

end


desc "レポートメール送信"
task :report do

  service = Application.instance.service
  service.report

end


desc "レポートメール送信"
task :sendmail, :message do |task, args|
  Application.instance.sendmail(args[:message])
end


desc "管理下のファイルのダウンロード用URLを発行する"
task :download, :file do |task, args|

  service = Application.instance.service
  puts service.download_url(args[:file])

end
