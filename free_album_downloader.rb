# encoding: UTF-8
require 'logger'
require 'faraday'
require 'json'
require 'fileutils'

class FreeAlbumDownloader

  LOGGER = Logger.new(STDOUT)
  ILLEGAL_FILENAME_CHARS = %r([|/?*:"<>\\])

  def initialize(album_id, storage_dir = '/tmp')
    @album_id = album_id
    @storage_dir = storage_dir
    @success_audios = []
    @failure_audios = []
  end

  def download
    FileUtils.mkdir_p(@storage_dir) unless Dir.exists?(@storage_dir)
    Dir.chdir(@storage_dir)
    need_break = false
    (1...100).each do |page|
      album_url = "/revision/play/album?albumId=#{@album_id}&pageNum=#{page}&pageSize=100&sort=0"
      response = connection.get do |request|
        request.url album_url
        request.headers['Accept'] = '*/*'
        request.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36'
      end
      body = JSON.parse(response.body)
      if body['ret'] == 200 and body['data'] and body['data']['tracksAudioPlay']
        audios = body['data']['tracksAudioPlay']
        batch_download(audios)
        need_break = true unless body['data']['hasMore']
      else
        LOGGER.error("Invalid body #{body} for album #{@album_id}")
      end
      break if need_break
    end
  end

  private
  def batch_download(audios)
    threads = []
    audios.each do |audio|
      threads << Thread.start { download_audio(audio) }
      if threads.length % 5 == 0
        threads.each(&:join)
        threads.clear
      end
    end
    threads.each(&:join)
  end

  def download_audio(audio)
    index = audio['index'] || 0
    name = sanitize_file_name(audio['trackName'])
    url = audio['src']
    if name and url
      ext = File.extname(url)
      filename = '%03d.%s%s' % [index, name, ext]
      if File.exists?(filename)
        puts "#{filename} have already downloaded!"
      else
        `wget #{url} --output-document=#{filename}`
      end
    end
  end

  def sanitize_file_name(name)
    name.gsub(ILLEGAL_FILENAME_CHARS, '_').gsub(/\s/, '')
  end

  def connection
    @connection ||= Faraday.new(url: 'https://www.ximalaya.com') do |faraday|
      faraday.request :url_encoded # form-encode POST params
      faraday.response :logger # log requests to STDOUT
      faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
    end
  end
end

if __FILE__ == $0
  downloader = FreeAlbumDownloader.new(18835582, '/tmp/test')
  downloader.download
end