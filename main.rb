# curl -X POST -H "Accept: application/json" -H "AuthenticationToken: auth" -H "Content-Type: application/json" -H "Host: addons-v2.forgesvc.net" -H "Content-Length: length of payload" -H "Expect: 100-continue" --data '[your murmurhash2 hash]' https://addons-v2.forgesvc.net//api/fingerprint
require 'digest/murmurhash'
require 'net/http'
require 'yaml'
require 'json'

class String
  def i?
    Integer(self)
    true
  rescue
    false
  end
end


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

puts('Would you like to update mods (1), search for mods (2), or search a wiki (3)?')
choice = gets.chomp

if choice == '1'

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

elsif choice == '2'
  # probably do dependancy checking lol
  puts 'NOTE: Dependancy installation is not implemented right now, so you will have to resolve that on your own.'
  puts 'Please give your minecraft version i.e. 1.12.2:'
  mc_version = gets.chomp
  puts 'Please give a search term:'
  search = gets.chomp
  mods = []
  search_root = URI("https://addons-v2.forgesvc.net/api/addon/search?gameId=432&sectionId=6&categoryId=0&gameVersion=#{mc_version}&index=0&pageSize=40&searchFilter=#{search}&sort=Featured&sortDescending=true")
  Net::HTTP.start(search_root.host, search_root.port, use_ssl: true) do |http|
    req = Net::HTTP::Get.new(search_root)
    req['Content-Type'] = 'application/json'
    req['AuthenticationToken'] = token

    JSON.parse(http.request(req).body).each do |mod|
      mods << mod
    end
  end
  mods.each_with_index do |mod, index|
    puts "Mod ##{index}:"
    puts "#{mod['name']} - #{mod['summary']}"
    puts "#{mod['websiteUrl']}"
    puts "\n"
  end
  puts "Type a mod number to install or x to exit"
  answer = gets.chomp
  return if answer == 'x'
  unless answer.i? && answer.to_i < mods.size && answer.to_i >= 0
    puts 'That is not a valid number.'
    return
  end

  download_mod = mods[answer.to_i]['gameVersionLatestFiles'].detect { |latestversionmod| mc_version == latestversionmod['gameVersion'] }
  mod_file_name = "#{ROOT}#{download_mod['projectFileName']}"

  Net::HTTP.start(search_root.host, search_root.port, use_ssl: true) do |http|
    req = Net::HTTP::Get.new(URI("https://addons-v2.forgesvc.net/api/addon/#{mods[answer.to_i]['id']}/file/#{download_mod['projectFileId']}"))
    req['Content-Type'] = 'application/json'
    req['AuthenticationToken'] = token
    download_url = JSON.parse(http.request(req).body)['downloadUrl'].gsub(' ', '%20')
    File.open(mod_file_name, 'w') do |f|
      r = Net::HTTP.get_response(URI(download_url))
      r = Net::HTTP.get_response(URI.parse(r.header['location'])) if r.code == '302'
      f.write(r.body)
    end
    puts "Downloaded #{mods[answer.to_i]['name']} as #{mod_file_name}."
  end

elsif choice == '3'
  puts 'not implemented yet lol'

else
  puts 'thats not a valid choice lol'
end