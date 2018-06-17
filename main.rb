# curl -X POST -H "Accept: application/json" -H "AuthenticationToken: auth" -H "Content-Type: application/json" -H "Host: addons-v2.forgesvc.net" -H "Content-Length: length of payload" -H "Expect: 100-continue" --data '[your murmurhash2 hash]' https://addons-v2.forgesvc.net//api/fingerprint
require 'digest/murmurhash'
require 'net/http'
require 'yaml'
require 'json'

# no clue how to generate one with username/pass for now so just use fiddler or wireshark or something to intercept your token
token = (YAML.load_file 'config.yaml')['token']

puts('Please place this script in the root of your modpack, 1 level up from the mods folder. Press y if it is')
unless gets.chomp.downcase == 'y'
  exit!
end

ROOT = 'mods/'
modlist = []

def refresh_modlist(modlist)
  modlist.clear
  Dir["#{ROOT}*.jar"].each do |mod|
    file = File.read(mod, File.size(mod)).gsub(9.chr, '').gsub(10.chr, '').gsub(13.chr, '').gsub(32.chr, '')
    modlist << {file: mod, hash: Digest::MurmurHash2.rawdigest(file, [1].pack("L"))}
  end
end

refresh_modlist(modlist)

fingerprint_root = URI('https://addons-v2.forgesvc.net//api/fingerprint')
addon_root = URI('https://addons-v2.forgesvc.net/api/addon')

# contains a hash of all the obtained hash info
# we are not just attaching each of the infos directly to the mod hashes from up above because:
# if 2 files that had the same fingerprint happened, the second would just be ignored by the api, breaking the index
modhashes = {}
Net::HTTP.start(fingerprint_root.host, fingerprint_root.port, use_ssl: true) do |http|
  req = Net::HTTP::Post.new(fingerprint_root)
  req['Content-Type'] = 'application/json'
  req['AuthenticationToken'] = token
  req.body = modlist.map { |mod| mod[:hash]}.to_s

  # hashinfo is the specific info on the hash of the file
  # hash -> fingerprint info
  JSON.parse(http.request(req).body)['exactMatches'].each_with_index do |hashinfo, index|
    modhashes[hashinfo['file']['packageFingerprint']] = hashinfo
  end
end

# contains a hash of modid -> info, is a hash because of the same reason as the modhashes
modinfos = {}
Net::HTTP.start(addon_root.host, addon_root.port, use_ssl: true) do |http|
  req = Net::HTTP::Post.new(addon_root)
  req['Content-Type'] = 'application/json'
  req['AuthenticationToken'] = token
  req.body = modlist.map { |mod| modhashes[mod[:hash]]['id']}.to_s

  # modinfo is the generic info on the curse API for the modid
  puts http.request(req).body
  JSON.parse(http.request(req).body).each_with_index do |modinfo, index|
    modinfos[modinfo['id']] = modinfo
  end
end
puts("\n\n\n\n\n\n")

modlist.each do |mod|
  mod_hash = modhashes[mod[:hash]]
  mod_info = modinfos[modhashes[mod[:hash]]['id']]
  latest_version_mod = mod_info['gameVersionLatestFiles'].detect { |latestversionmod| latestversionmod['gameVersion'] == mod_hash['file']['gameVersion'].first }
  puts mod_info['name'] + ' ' + mod[:file] + ' ' + mod_hash['file']['fileName'] + ' ' + mod_hash['id'].to_s
  puts latest_version_mod
  
  if latest_version_mod['projectFileName'] != mod_hash['file']['fileName']
    version_root = URI("https://addons-v2.forgesvc.net/api/addon/#{mod_hash['id']}/file/#{latest_version_mod['projectFileId']}")
    download_url =
      Net::HTTP.start(version_root.host, version_root.port, use_ssl: true) do |http|
        req = Net::HTTP::Get.new(version_root)
        req['Content-Type'] = 'application/json'
        req['AuthenticationToken'] = token
      
        # modinfo is the generic info on the curse API for the modid
        JSON.parse(http.request(req).body)['downloadUrl']
      end
    puts 'mod is outdated lmfoa'
    puts "Latest download url: #{download_url}"
  else
    puts 'on latest version'
  end
  puts "\n"
rescue
  puts "something broke lol, error from file: #{mod[:file]}"
end