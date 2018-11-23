require 'faraday'
require 'logger'
require_relative 'fileid_decoder'
require_relative 'params_decryptor'

LOGGER = Logger.new(STDOUT)
ILLEGAL_FILENAME_CHARS = %r([|/?*:"<>\\])

class AudioDownloader

  def initialize(uid, token)
    @decryptor = ParamsDecryptor.new
    @uid = uid
    @token = token
  end

  def batch_download(audio_ids, dir)
    audio_ids.each do |audio_id|
      download(audio_id, dir)
    end
  end

  def download(audio_id, dir)
    audio_desc = get_audio_desc(audio_id)
    audio = get_audio_resp(audio_desc)
    total_length = audio_desc['totalLength']
    content_length = audio.headers['content-length']
    filename = sanitize_file_name(audio_desc['title'])
    if total_length and content_length and total_length == content_length.to_i
      open "/#{dir}/#{filename}.m4a", 'wb' do |io|
        io << audio.body
      end
      LOGGER.info("[#{audio_id}]_#{filename} with length #{total_length} download successful.")
      yield "#{audio_id}_#{filename}", true if block_given?
    else
      if audio.status == 206
        processed_length = content_length.to_i
        open "/#{dir}/#{filename}.m4a", 'wb' do |io|
          io << audio.body
          while processed_length < total_length
            partial_audio = get_audio_resp(audio_desc) do |req|
              req.headers['Range'] = "bytes=#{processed_length}-#{total_length - 1}"
            end
            partial_content_length = partial_audio.headers['content-length'].to_i
            processed_length += partial_content_length
            io << partial_audio.body
          end
        end
        LOGGER.info("[#{audio_id}]_#{filename} with length #{processed_length} download successful.")
        yield "#{audio_id}_#{filename}", true if block_given?
      else
        LOGGER.error("[#{audio_id}] download failure with response (#{audio.status}, #{audio.headers}).")
        yield "#{audio_id}_#{filename}", false if block_given?
      end
    end
  end

  private

  def get_audio_resp(audio_desc)
    decoder = FileidDecoder.new(audio_desc['seed'])
    url = "#{audio_desc['domain']}/download/#{audio_desc['apiVersion']}/#{decoder.decode(audio_desc['fileId'])}"
    params = @decryptor.decrypt(audio_desc['ep']).split('-')
    connection.get do |req|
      req.url url, {
          sign: params[1],
          buy_key: params[0],
          token: params[2],
          timestamp: params[3],
          duration: audio_desc['duration']
      }
      req.headers['Accept-Encoding'] = 'identity;q=1, *;q=0'
      req.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.59 Safari/537.36'
      yield req if block_given?
    end
  end

  def get_audio_desc(audio_id)
    resp = mpay_connection.get do |req|
      req.url "/mobile/track/pay/#{audio_id}", {
          device: 'pc',
          uid: @uid,
          token: @token,
          isBackend: false
      }
      req.headers['Accept'] = 'application/json, text/javascript, */*; q=0.01'
      req.headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.59 Safari/537.36'
      req.headers['Host'] = 'mpay.ximalaya.com'
    end
    JSON.parse(resp.body)
  end

  def mpay_connection
    @mpay_connection ||= Faraday.new(url: 'https://mpay.ximalaya.com') do |faraday|
      faraday.request :url_encoded # form-encode POST params
      faraday.response :logger # log requests to STDOUT
      faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
    end
  end

  def connection
    @connection ||= Faraday.new(url: 'http://audio.pay.xmcdn.com') do |faraday|
      faraday.request :url_encoded
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
    end
  end

  def sanitize_file_name(name)
    name.gsub(ILLEGAL_FILENAME_CHARS, '_').gsub(/\s/, '')
  end

end