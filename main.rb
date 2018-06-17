# curl -X POST -H "Accept: application/json" -H "AuthenticationToken: auth" -H "Content-Type: application/json" -H "Host: addons-v2.forgesvc.net" -H "Content-Length: length of payload" -H "Expect: 100-continue" --data '[your murmurhash2 hash]' https://addons-v2.forgesvc.net//api/fingerprint
require 'digest/murmurhash'
require 'net/http'
require 'yaml'
require 'json'

# no clue how to generate one with username/pass for now so just use fiddler or wireshark or something to intercept your token
token = (YAML.load_file 'config.yaml')['token']

puts('Please drag in or type in the directory of your mod folder (no need to escape whitespace) and then press enter.')
# terrible hack because File.directory works fine with windows directories but not with Dir
ROOT = gets.chomp.gsub('\\', '/').gsub('"', '') + '/'
modlist = []

def refresh_modlist(modlist)
  modlist.clear
  Dir["#{ROOT}*.jar"].each do |mod|
    # oddly faster than tr???
    file = File.read(mod, File.size(mod)).gsub(9.chr, '').gsub(10.chr, '').gsub(13.chr, '').gsub(32.chr, '')
    modlist << { file: mod, hash: Digest::MurmurHash2.rawdigest(file, [1].pack('L')) }
  end
end

refresh_modlist(modlist)

fingerprint_root = URI('https://addons-v2.forgesvc.net/api/fingerprint')
addon_root = URI('https://addons-v2.forgesvc.net/api/addon')

# contains a hash of all the obtained hash info
# we are not just attaching each of the infos directly to the mod hashes from up above because:
# if 2 files that had the same fingerprint happened, the second would just be ignored by the api, breaking the index
modhashes = {}
Net::HTTP.start(fingerprint_root.host, fingerprint_root.port, use_ssl: true) do |http|
  req = Net::HTTP::Post.new(fingerprint_root)
  req['Content-Type'] = 'application/json'
  req['AuthenticationToken'] = token
  req.body = modlist.map { |mod| mod[:hash] }.to_s

  # hashinfo is the specific info on the hash of the file
  # hash -> fingerprint info
  JSON.parse(http.request(req).body)['exactMatches'].each do |hashinfo|
    modhashes[hashinfo['file']['packageFingerprint']] = hashinfo
  end


  # remove invalid mods
  unknown_mods = []
  modlist.delete_if do |mod|
    unknown_mods << mod[:file].sub(ROOT, '') unless modhashes[mod[:hash]]
  end

  # contains a hash of modid -> info, is a hash because of the same reason as the modhashes
  modinfos = {}
  req = Net::HTTP::Post.new(addon_root)
  req['Content-Type'] = 'application/json'
  req['AuthenticationToken'] = token
  req.body = modlist.map { |mod| modhashes[mod[:hash]]['id'] }.to_s

  # modinfo is the generic info on the curse API for the modid
  JSON.parse(http.request(req).body).each do |modinfo|
    modinfos[modinfo['id']] = modinfo
  end

  modlist.each do |mod|
    mod_hash = modhashes[mod[:hash]]
    mod_info = modinfos[modhashes[mod[:hash]]['id']]
    # mod_hash['file']['gameVersion'] is a array while latestversionmod['gameVersion'] is a string wtf
    latest_version_mod = mod_info['gameVersionLatestFiles'].detect { |latestversionmod| mod_hash['file']['gameVersion'].include? latestversionmod['gameVersion'] }
    puts "#{mod[:file].sub(ROOT, '')} - "
    if latest_version_mod['projectFileName'] != mod_hash['file']['fileName']
      req = Net::HTTP::Get.new(URI("https://addons-v2.forgesvc.net/api/addon/#{mod_hash['id']}/file/#{latest_version_mod['projectFileId']}"))
      req['Content-Type'] = 'application/json'
      req['AuthenticationToken'] = token
      # should probably do correct uri encoding but whatever lmfoa
      download_url = JSON.parse(http.request(req).body)['downloadUrl'].gsub(' ', '%20')

      puts 'Mod is outdated, updating...'
      new_mod_filename = "#{ROOT}#{latest_version_mod['projectFileName']}"
      # some mods dont end with jar for some reason lol
      new_mod_filename << '.jar' unless new_mod_filename.end_with?('.jar')
      File.open(new_mod_filename, 'w') do |f|
        r = Net::HTTP.get_response(URI(download_url))
        r = Net::HTTP.get_response(URI.parse(r.header['location'])) if r.code == '302'
        f.write(r.body)
      end
      File.delete(mod[:file])
      puts 'Updated mod to latest version.'
      sleep(0.5)
    else
      puts 'Mod is on latest version.'
    end
    puts "\n"
  rescue
    puts "something broke lol, error from file: #{mod[:file]}"
  end

  puts "Some mod files were unable to be identified and were not updated (do they exist on curseforge?): #{unknown_mods.join(' ')}" unless unknown_mods.empty?
end

# Now the mod list is in a possibly broken state if we were to do anything else in the current runtime, so we would have to rerun filesystem fetching/hashing/getting mod info
# so lol probably never gonna do that

puts 'Updating complete!'
