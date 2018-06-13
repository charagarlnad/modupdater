# HOW
# ok so like you just take the file and get the murmurhash2 of it and then do a curl like
# curl -X POST -H "Accept: application/json" -H "AuthenticationToken: auth" -H "Content-Type: application/json" -H "Host: addons-v2.forgesvc.net" -H "Content-Length: length of payload" -H "Expect: 100-continue" --data '[your murmurhash2 hash]' https://addons-v2.forgesvc.net//api/fingerprint
# lmfoa
# im literally shaking i never thought i could figure out that FUCKING binary decompilers have much more to go
# ill probably rewrite this with actual docs and shit when im done freaking out
# only the cs version works for now because i just decompiled part of the twitch client lmao

def computeNormalizedLength(data)
  len = 0
  data.each_byte do |byte|
    len += 1 unless byte == 9 || byte == 10 || byte == 13 || byte == 32
  end
  len
end

module Digest
  def self.murmur_hash2(string)
    seed = 1

    m = 0x5bd1e995
    r = 24
    len = computeNormalizedLength(string)
    puts(len)

    h = ( seed ^ len )

    while len >= 4
      string.scan( /..../ ) do |data|

        # Ruby 1.8/1.9 compatibility fix
        data = data.bytes.to_a

        k = data[0]
        k |= data[1] << 8
        k |= data[2] << 16
        k |= data[3] << 24

        k = ( k * m ) % 0x100000000
        k ^= k >> r
        k = ( k * m ) % 0x100000000

        h = ( h * m ) % 0x100000000
        h ^= k

        len -= 4
      end
    end

    # Ruby 1.8/1.9 compatibility fix
    string = string.bytes.to_a

    if len == 3 then
      h ^= string[-1] << 16
      h ^= string[-2] << 8
      h ^= string[-3]
    end
    if len == 2 then
      h ^= string[-1] << 8
      h ^= string[-2]
    end
    if len == 1 then
      h ^= string[-1]
    end

    h = ( h * m ) % 0x100000000
    h ^= h >> 13
    h = ( h * m ) % 0x100000000
    h ^= h >> 15

    return h
  end
end
require 'digest/murmurhash'
data = ''
File.read('test.jar', File.size('test.jar')).each_byte do |byte|
  data << byte.chr unless byte == 9 || byte == 10 || byte == 13 || byte == 32
end
puts Digest.murmur_hash2(data)
puts Digest::MurmurHash2.rawdigest(data, [1].pack("L"))
