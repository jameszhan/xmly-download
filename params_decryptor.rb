CHAR_MAP = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63, 52, 53, 54,
            55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
            15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34,
            35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1];

class ParamsDecryptor

  def initialize(seed = 'xkt3a41psizxrh9l')
    @seed = seed
  end

  def decrypt(ep)
    do_decrypt(@seed, pre_decrypt(ep))
  end

  private
  def pre_decrypt(ep)
    return '' if ep.nil? || ep.empty?
    n = ep.length
    i = 0
    s = ''
    while i < n
      begin
        e = CHAR_MAP[255 & ep[i].ord]
        i += 1
      end while i < n and e == -1
      break if -1 == e

      begin
          f = CHAR_MAP[255 & ep[i].ord]
          i += 1
      end while i < n and -1 == f
      break if -1 == f

      s << (e << 2 | (48 & f) >> 4).chr

      begin
          return s if 61 == (e = 255 & ep[i].ord)
          i += 1
          e = CHAR_MAP[e]
      end while i < n and -1 == e
      break if -1 == e

      s << ((15 & f) << 4 | (60 & e) >> 2).chr

      begin
        return s if 61 == (f = 255 & ep[i].ord)
        i += 1
        f = CHAR_MAP[f]
      end while i < n && -1 == f
      break if -1 == f

      s << ((3 & e) << 6 | f).chr
    end
    s
  end

  def do_decrypt(key, ep)
    chars = []
    (0...256).each do |i|
      chars[i] = i
    end
    n = 0
    (0...256).each do |i|
      n = (n + chars[i] + key[i % key.length].ord) % 256
      chars[i], chars[n] = chars[n], chars[i]
    end

    str = ''
    s = n = i = 0
    while i < ep.length
      s = (s + 1) % 256
      n = (n + chars[s]) % 256
      chars[n], chars[s] = chars[s], chars[n]
      str << (ep[i].ord ^ chars[(chars[s] + chars[n]) % 256]).chr
      i += 1
    end
    str
  end

end


if __FILE__ == $0
  decryptor = ParamsDecryptor.new
  encrypt_params = '3kFqaox2SndSj6gJPoocsAtdUxUghSLGTowfeV+0DX6qnbmF3q+Kmu9b0f6P1KJrXuV013EEeqdi0vL3wAMW3rwVOylUHb6iWNzDuDxcqRKro+RYnTkRM6gvcTKBAUOReczeQshNrmE8/fT4631Ye4C0DIkeiohLnqpn+1X8VUzh8Bk=';
  decrypt_params = decryptor.decrypt(encrypt_params)
  puts decrypt_params
end
