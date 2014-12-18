#!/usr/bin/ruby -Ku 
# -*- coding: utf-8 -*-

# 使用法：　このコマンド マシンリストファイル コマンド…

require 'pty'

unless machine_file = ARGV.shift
  raise "Usage: #{$0} machine_list.txt command... "
end
command = ARGV.join(' ')

def get_pw
  system "stty -echo"
  pass = STDIN.gets
  system "stty echo"
  pass
end

pw = nil
f = open(machine_file)  rescue raise("Error: #{machine_file.to_s}, #{$!}")
machine_list = f.read.split("\n")
machine_list.each do |h|
  cmd =  "ssh -t #{h} '#{command}'"
  begin
    PTY.getpty(cmd) do  |i,o|
      o.sync = true
      line = "#{h}: "
      while (i.eof? == false)
        c = i.getc
        line << c
        if c == 0x0A
          print line
          line = "#{h}: " # 行の先頭にホスト名を表示させている。
        end
        if pw and line.index('Sorry, try again.')
          print line; line = '' # lineを初期化することにより、マッチさせないようにしている。
          pw = nil
        elsif line =~ /\[sudo\] password for.+: /
          print line; line = ''
          pw = get_pw() if pw.nil?
          o.puts pw
          o.flush
        end
      end
    end 
  rescue PTY::ChildExited # すぐにptyを作りなおすと、失敗することがある。
    retry    
  end
  # 最後の改行以降は表示していないが、必要ならここにprint lineを書くこと。
end
