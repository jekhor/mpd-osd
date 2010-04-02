#!/usr/bin/ruby
# encoding: utf-8

$KCODE="UTF8"

require 'rubygems'
require 'librmpd'
#require 'xosd'

class OsdMpdClient
  def initialize
    @mpd = MPD.new
#    @xosd = Xosd.new(1)
    @osd_pipe = IO.popen("osd_cat -p middle -A center -s 0 -l 1 -f '-*-*-*-*-*-*-40-*-*-*-*-*-iso10646-1'  -d 4 -c \\#22cc22 -O 1 -u \\#004400", "w")

    @mpd.register_callback(self.method('song_cb'), MPD::CURRENT_SONG_CALLBACK)
    @mpd.register_callback(self.method('connection_cb'), MPD::CONNECTION_CALLBACK)
    @mpd.register_callback(self.method('random_cb'), MPD::RANDOM_CALLBACK)
    @mpd.register_callback( self.method('state_cb'), MPD::STATE_CALLBACK )
  end

  def start
    @connection_thread = Thread.new do
      while true do
        begin
          @mpd.connect(true) unless @mpd.connected?
          @mpd.ping if @mpd.connected?
          sleep(60) if @mpd.connected?
        rescue
        end
      end
    end

    @connection_thread.join
  end

  def stop
    @connection_thread.kill
  end

  private

  def song_cb(current)
    xosd_display_song(current)
    puts "#{current.artist} (#{current.album}) - #{current.title}"
  end

  def connection_cb(connected)
    if connected
      puts "Connected"
    else
      puts "Disconnected"
      @connection_thread.wakeup
    end
  end

  def random_cb(rnd)
    @osd_pipe.puts rnd ? "Random: On" : "Random Off"
    puts rnd ? "Random: On" : "Random Off"
  end

  def state_cb(state)
    @osd_pipe.puts "State: " + state
    puts "State: " + state
  end

  def xosd_display_song(song)
    album = ''
    album = "(#{song.album}) " unless song.album.nil?

    artist = 'Unknown artist '
    artist = "#{song.artist} " unless song.artist.nil?

    title = song.title
    title = File.basename(song.file) if title.nil?

#    @xosd.font = "-misc-computer modern-*-i-*-*-40-*-*-*-*-*-iso10646-1"
#    @xosd.align = 'center'
#    @xosd.valign = 'middle'
#    @xosd.timeout = 2
#    @xosd.display "#{artist}#{album}- #{song.title}"
    @osd_pipe.puts "#{artist}#{album}- #{title}"
  end
end

client = OsdMpdClient.new

client.start
