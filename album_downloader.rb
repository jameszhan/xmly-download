require 'nokogiri'
require 'faraday'
require 'json'
require_relative 'audio_downloader'

class AlbumDownloader

  def initialize(album_id, category, uid, token, storage_dir='/tmp')
    @album_id = album_id
    @category = category
    @storage_dir = storage_dir
    @uid = uid
    @token = token
    @success_audios = []
    @failure_audios = []
  end

  def download
    album_url = "/#{@category}/#{@album_id}/"
    doc = get_album_page album_url
    batch_download(doc)
    input = doc.at('div.rC5T.pagination input[type="number"]')
    if input and input.attr('max')
      max = input.attr('max')
      total_page = max.is_a? String ? max.to_i : max.value.to_i
      if total_page > 1
        total_page.downto(2) do |page|
          doc = get_album_page "#{album_url}p#{page}/"
          batch_download(doc)
        end
      end
    end
  ensure
    open "#{@storage_dir}/#{@category}_#{@album_id}_success.log", 'w:UTF-8' do |io|
      @success_audios.each do |audio|
        io << audio
        io << "\n"
      end
    end
    open "#{@storage_dir}/#{@category}_#{@album_id}_failure.log", 'w:UTF-8' do |io|
      @failure_audios.each do |audio|
        io << audio
        io << "\n"
      end
    end
  end

  private
  def batch_download(doc)
    doc.css('ul.rC5T li').each do |li|
      link = li.at('div.text.rC5T a')
      href = link.attr('href')
      audio_id = href.split('/')[-1]
      audio_downloader.download(audio_id, @storage_dir) do |audio, success|
        if success
          @success_audios << audio
        else
          @failure_audios << audio
        end
      end
    end
  end

  def get_album_page(album_url)
    response = connection.get do |request|
      request.url album_url
      request.headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8'
      request.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.59 Safari/537.36'
    end
    Nokogiri::HTML(response.body)
  end

  def connection
    @connection ||= Faraday.new(url: 'https://www.ximalaya.com') do |faraday|
      faraday.request :url_encoded # form-encode POST params
      faraday.response :logger # log requests to STDOUT
      faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
    end
  end

  def audio_downloader
    @audio_downloader ||= AudioDownloader.new(@uid, @token)
  end

end

if __FILE__ == $0
  downloader = AlbumDownloader.new(4417201, 'keji', ENV['XMLY_UID'], ENV['XMLY_TOKEN'])
  downloader.download
end




