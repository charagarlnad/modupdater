# HOW
# ok so like you just take the file and get the murmurhash2 of it and then do a curl like
# curl -X POST -H "Accept: application/json" -H "AuthenticationToken: auth" -H "Content-Type: application/json" -H "Host: addons-v2.forgesvc.net" -H "Content-Length: length of payload" -H "Expect: 100-continue" --data '[your murmurhash2 hash]' https://addons-v2.forgesvc.net//api/fingerprint
# lmfoa
# im literally shaking i never thought i could figure out that FUCKING binary decompilers have much more to go
# ill probably rewrite this with actual docs and shit when im done freaking out
# only the cs version works for now because i just decompiled part of the twitch client lmao
def ComputeNormalizedLength(data)

end
require 'digest/murmurhash'
puts Digest::MurmurHash2.rawdigest(File.read('test.jar'))
