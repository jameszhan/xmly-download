# cg_fun: function(t) {
#   var t = t.split("*"), e = "", i = 0;
#   for (i = 0; i < t.length - 1; i++)
#     e += this._cgStr.charAt(t[i]);
#   return e
# }
#
# cg_hun: function() {
#   this._cgStr = "";
#   var t = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ/\\:._-1234567890"
#     , e = t.length
#     , i = 0;
#
#   for (i = 0; i < e; i++) {
#       var o = this.ran() * t.length, n = parseInt(o);
#       this._cgStr += t.charAt(n),
#       t = t.split(t.charAt(n)).join("")
#   }
# }
#
# ran: function() {
#     return this._randomSeed = (211 * this._randomSeed + 30031) % 65536, this._randomSeed / 65536
# }

class FileidDecoder

  def initialize(seed)
    @random_seed = seed
  end

  def decode(str)
    @words ||= gen_dict
    ids = str.split("*").map(&:to_i)
    str = ''
    i = 0
    while i < ids.length do
      str << @words[ids[i]]
      i += 1
    end
    str
  end

  def gen_dict
    target_str = ''
    t = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ/\\:._-1234567890"
    l = t.length
    i = 0
    while i < l do
      n = (self.next_seed * t.length).to_i
      target_char = t[n]
      target_str << target_char
      t = t.split(target_char).join('')
      i += 1
    end
    target_str
  end

  def next_seed
    @random_seed = (211 * @random_seed + 30031) % 65536
    @random_seed / 65536.0
  end

end

if __FILE__ == $0
  decoder = FileidDecoder.new(5663)
  filename = decoder.decode('51*60*8*53*1*30*42*43*38*38*42*38*23*42*52*23*42*14*26*51*41*50*30*25*40*36*54*19*35*64*7*65*18*48*47*36*31*36*17*60*56*35*57*66*23*62*23*49*20*21*10*')
  puts filename
end
