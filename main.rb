# curl -X POST -H "Accept: application/json" -H "AuthenticationToken: auth" -H "Content-Type: application/json" -H "Host: addons-v2.forgesvc.net" -H "Content-Length: length of payload" -H "Expect: 100-continue" --data '[your murmurhash2 hash]' https://addons-v2.forgesvc.net//api/fingerprint
require 'digest/murmurhash'
require 'net/http'
require 'yaml'
require 'json'

# no clue how to generate one with username/pass for now so just use fiddler or wireshark or something to intercept your token
token = (YAML.load_file 'config.yaml')['token']

puts('Please place me in the root of your modpack, 1 level up from the mods folder.')
root = 'mods/'
modlist = []
Dir["#{root}*.jar"].each do |mod|
  file = File.read(mod, File.size(mod)).gsub(9.chr, '').gsub(10.chr, '').gsub(13.chr, '').gsub(32.chr, '')
  modlist << {file: mod, hash: Digest::MurmurHash2.rawdigest(file, [1].pack("L"))}
  puts("Done hashing #{mod}")
end
modlist.each do |mod|
  puts("File: #{mod[:file]}, Hash: #{mod[:hash]}")
end

fingerprint_root = URI('https://addons-v2.forgesvc.net//api/fingerprint')
addon_root = URI('https://addons-v2.forgesvc.net/api/addon')
modlist.each do |mod|
  Net::HTTP.start(fingerprint_root.host, fingerprint_root.port, use_ssl: true) do |http|
    req = Net::HTTP::Post.new(fingerprint_root)
    req['Content-Type'] = 'application/json'
    req['AuthenticationToken'] = token
    req.body = "[#{mod[:hash]}]"

    mod[:curse] = JSON.parse(http.request(req).body)
  end
  puts mod[:curse]
  puts("\n\n\n\n\n\n")
  modid = mod[:curse]['exactMatches'].first['id']
  Net::HTTP.start(addon_root.host, addon_root.port, use_ssl: true) do |http|
    req = Net::HTTP::Post.new(addon_root)
    req['Content-Type'] = 'application/json'
    req['AuthenticationToken'] = token
    req.body = "[#{modid}]"

    mod[:mod] = JSON.parse(http.request(req).body)
  end
  puts mod[:mod]
end
