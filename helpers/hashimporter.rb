# encoding: utf-8
#require './model/master'
#def detectedHashFormat(hash)
#  # Detect if pwdump file format
#  if hash =~ /^[^:]+:\d+:.*:.*:.*:.*:$/
#    return 'pwdump'
#  # Detect if shadow
#  elsif hash =~ /^.*:.*:\d*:\d*:\d*:\d*:\d*:\d*:$/
#    return 'shadow'
#  elsif hash =~ /^.*:(\$NT\$)?\w{32}:.*:.*:/ # old version of dsusers
#    return 'dsusers'
#  elsif hash =~ /^.*:\w{32}$/
#    return 'dsusers'
#  elsif hash =~ /^.*:\w.*/
#    return 'generic'
#  elsif hash =~ /^\w{32}$/
#    return 'ntlm_only'
#  elsif hash =~ /.*:\d*:\w{32}:\w{32}$/
#    return 'smart hashdump'
#  else
#    return 'File Format or Hash not supported'
#  end
#end

def addHash(hash, hashtype)

  @hashes.insert(:originalhash=> hash, :hashtype=>hashtype, :cracked=>false)

end

def updateHashfileHashes(hash_id, username, hashfile_id)

  @hashfilehashes.insert(:hash_id=>hash_id, :username=>username, :hashfile_id=>hashfile_id)

end

def importPwdump(hash, hashfile_id, type)
  data = hash.split(':')
  return if machineAcct?(data[0])
  return if data[2].nil?
  return if data[3].nil?

  # if hashtype is lm
  if type == '3000'
    # import LM
    lm_hashes = data[2].scan(/.{16}/)
    lm_hash_0 = lm_hashes[0].downcase
    lm_hash_1 = lm_hashes[1].downcase
 
    @hash_id = @hashes.where(:originalhash => lm_hash_0, :hashtype=>type).first[:id]
    if @hash_id.nil?
      addHash(lm_hash_0, type)
    @hash_id = @hashes.where(:originalhash => lm_hash_0, :hashtype=>type).first[:id]
    end

    updateHashfileHashes(@hash_id.id.to_i, data[0], hashfile_id)

    @hash_id = @hashes.where(:originalhash => lm_hash_1, :hashtype=>type).first[:id]
    if @hash_id.nil?
      addHash(lm_hash_1, type)
    @hash_id = @hashes.where(:originalhash => lm_hash_1, :hashtype=>type).first[:id]
    end

    updateHashfileHashes(@hash_id.id.to_i, data[0], hashfile_id)
  end

  # if hashtype is ntlm
  if type == '1000'
    @hash_id = @hashes.where(:originalhash => data[3], :hashtype=>type).first[:id]
    if @hash_id.nil?
      addHash(data[3], type)
    @hash_id = @hashes.where(:originalhash => data[3], :hashtype=>type).first[:id]
    end

    updateHashfileHashes(@hash_id.id.to_i, data[0], hashfile_id)
  end
end

def machineAcct?(username)
  if username =~ /\$/
    return true
  else
    return false
  end
end

def importShadow(hash, hashfile_id, type)
  # This parser needs some work
  data = hash.split(':')
  @hash_id = @hashes.where(:originalhash => data[1], :hashtype=>type).first[:id]
  if @hash_id.nil?
    addHash(data[1], type)
    @hash_id = @hashes.where(:originalhash => data[1], :hashtype=>type).first[:id]
  end

  updateHashfileHashes(@hash_id.id.to_i, data[0], hashfile_id)
end

def importDsusers(hash, hashfile_id, type)
  data = hash.split(':')
  if data[1] =~ /NT/
    data[1] = data[1].to_s.split('$')[2]
    type = '3000'
  end

  @hash_id = @hashes.where(:originalhash => data[1], :hashtype=>type).first[:id]
  if @hash_id.nil?
    addHash(data[1], type)
    @hash_id = @hashes.where(:originalhash => data[1], :hashtype=>type).first[:id]
  end

  updateHashfileHashes(@hash_id.id.to_i, data[0], hashfile_id)
end

def importUserHash(hash, hashfile_id, type)
  data = hash.split(':')
  @hash_id = @hashes.where(:originalhash => data[1], :hashtype=>type).first[:id]
  if @hash_id.nil?
    addHash(data[1], type)
    @hash_id = @hashes.where(:originalhash => data[1], :hashtype=>type).first[:id]
  end

  updateHashfileHashes(@hash_id.id.to_i, data[0], hashfile_id)
end

def importHashSalt(hash, hashfile_id, type)
  @hash_id = @hashes.where(:originalhash => hash, :hashtype=>type).first[:id]
  if @hash_id.nil?
    addHash(hash, type)
    @hash_id = @hashes.where(:originalhash => hash, :hashtype=>type).first[:id]
  end

  updateHashfileHashes(@hash_id.id.to_i, 'null', hashfile_id)
end

def importNetNTLMv1(hash, hashfile_id, type)
  data = hash.split(':')
  originalhash = data[3].to_s.downcase + ':' + data[4].to_s.downcase + ':' + data[5].to_s.downcase

  @hash_id = @hashes.where(:originalhash => originalhash, :hashtype=>type).first[:id]
  if @hash_id.nil?
    addHash(originalhash, type)
    @hash_id = @hashes.where(:originalhash => originalhash, :hashtype=>type).first[:id]
  end

  updateHashfileHashes(@hash_id.id.to_i, data[0], hashfile_id)
end

def importNetNTLMv2(hash, hashfile_id, type)
c  data = hash.split(':')

  @hash_id = @hashes.where(:originalhash => hash, :hashtype=>type).first[:id]
  if @hash_id.nil?
    addHash(hash, type)
    @hash_id = @hashes.where(:originalhash => hash, :hashtype=>type).first[:id]
  end

  updateHashfileHashes(@hash_id.id.to_i, data[0], hashfile_id)
end

def importHashOnly(hash, hashfile_id, type)
  if type == '3000'
    # import LM
    lm_hashes = hash.scan(/.{16}/)
    lm_hash_0 = lm_hashes[0].downcase
    lm_hash_1 = lm_hashes[1].downcase

    @hash_id = @hashes.where(:originalhash => lm_hash_0, :hashtype=>type).first[:id]
    if @hash_id.nil?
      addHash(lm_hash_0, type)
      @hash_id = @hashes.where(:originalhash => lm_hash_0, :hashtype=>type).first[:id]
    end

    updateHashfileHashes(@hash_id.id.to_i, 'NULL', hashfile_id)

    @hash_id = @hashes.where(:originalhash => lm_hash_1, :hashtype=>type).first[:id]
    if @hash_id.nil?
      addHash(lm_hash_1, type)
      @hash_id = @hashes.where(:originalhash => lm_hash_1, :hashtype=>'3000').first[:id]
    end

    updateHashfileHashes(@hash_id.id.to_i, 'NULL', hashfile_id)

  elsif type == '5500'
    # import NetNTLMv1
    fields = hash.split(':')
    originalhash = fields[3].to_s.downcase + ':' + fields[4].to_s.downcase + ':' + fields[5].to_s.downcase

    @hash_id = @hashes.where(:originalhash => originalhash, :hashtype=>type).first[:id]
    if @hash_id.nil?
      addHash(originalhash, type)
      @hash_id = @hashes.where(:originalhash => originalhash, :hashtype=>type).first[:id]
    end

    updateHashfileHashes(@hash_id.id.to_i, fields[0], hashfile_id)

  elsif type == '5600'
    # We need to include full hash (username, salt, computername)
    # import NetNTLMv2
    fields = hash.split(':')

    @hash_id = @hashes.where(:originalhash => hash, :hashtype=>type).first[:id]
    if @hash_id.nil?
      addHash(hash, type)
      @hash_id = @hashes.where(:originalhash => hash, :hashtype=>type).first[:id]
    end

    updateHashfileHashes(@hash_id.id.to_i, fields[0], hashfile_id)

  else
    
    @hash_id = @hashes.where(:originalhash => hash, :hashtype=>type).first[:id]
    if @hash_id.nil?
      addHash(hash, type)
      @hash_id = @hashes.where(:originalhash => hash, :hashtype=>type).first[:id]
    end
    updateHashfileHashes(@hash_id.to_i, 'NULL', hashfile_id)
    
  end
end

def getMode(hash)
  @modes = []
  if hash =~ /^\w{32}$/
    @modes.push('0')	  # MD5
    # @modes.push('23')   # Skype (has backdoors)
    @modes.push('900')  # MD4
    @modes.push('1000') # NTLM
    @modes.push('2600') # Double MD5
    @modes.push('3000') # LM (in pwdump format)
    @modes.push('3500') # md5(md5(md5($pass)))
    @modes.push('4300') # md5(strtroupper(md5($pass)))
    @modes.push('4400') # md5(sha1($pass))
    @modes.push('8600') # Lotus Notes/Domino 5
  elsif hash =~ /^[a-f0-9]{32}:.+$/
    @modes.push('10')   # md5($pass.$salt)
    @modes.push('20')   # md5($salt.$pass)
    @modes.push('30')   # md5(unicode($pass).$salt)
    @modes.push('40')   # md5($salt.unicode($pass))
    @modes.push('50')   # HMAC-MD5 (key = $pass)
    @modes.push('60')   # HMAC-MD5 (key = $salt)
    @modes.push('3610') # md5(md5($salt).$pass)
    @modes.push('3710') # md5($salt.md5($pass))
    @modes.push('3720') # md5($pass.md5($salt))
    @modes.push('3800') # md5($salt.$pass.$salt)
    @modes.push('3910') # md5(md5($pass).md5($salt))
    @modes.push('4010') # md5($salt.md5($salt.$pass))
    @modes.push('4110') # md5($salt.md5($pass.$salt))
    # @modes.push('4210') # md5($username.0.$pass) # Legacy
    @modes.push('11000')# PrestaShop
  elsif hash =~ %r{\$NT\$\w{32}} # NTLM
    @modes.push('1000')
  elsif hash =~ /^[a-f0-9]{40}$/
    @modes.push('100')  # SHA-1
    @modes.push('190')  # sha1(LinkedIn)
    @modes.push('300')  # MySQL4.1/MySQL5
    @modes.push('4500') # sha1(sha1($pass))
    @modes.push('4600') # sha1(sha1(sha1($pass)))
    @modes.push('4700') # sha1(md5($pass))
    @modes.push('6000') # RipeMD160
  elsif hash =~ /^[a-f0-9]{40}:.+$/
    @modes.push('110')  # sha1($pass.$salt)
    @modes.push('120')  # sha1($salt.$pass)
    @modes.push('130')  # sha1(unicode($pass).$salt)
    @modes.push('140')  # sha1($salt.unicode($pass))
    @modes.push('150')  # HMAC-SHA1 (key = $pass)
    @modes.push('160')  # HMAC-SHA1 (key = $salt)
    @modes.push('4520') # sha1($salt.sha1($pass))
    @modes.push('4900') # sha1($salt.$pass.$salt)
  elsif hash =~ %r{^\$1\$[\.\/0-9A-Za-z]{0,8}\$[\.\/0-9A-Za-z]{22}$}
    @modes.push('500') 	# md5crypt
  elsif hash =~ /^[0-9A-Za-z]{16}$/
    @modes.push('200')  # MySQL323
    @modes.push('3000') # LM
    @modes.push('3100') # Oracle 7-10g, DES(Oracle)
    @modes.push('5100') # Half MD5
  elsif hash =~ /\$\d+\$.{53}$/
    @modes.push('3200')	# bcrypt, Blowfish(OpenBSD)
  elsif hash =~ %r{^\$5\$rounds=\d+\$[\.\/0-9A-Za-z]{0,16}\$[\.\/0-9A-Za-z]{0,43}$}
    @modes.push('7400')	# sha256crypt, SHA256(Unix)
  elsif hash =~ %r{^\$6\$[\.\/0-9A-Za-z]{4,9}\$[\.\/0-9A-Za-z]{86}$}
    @modes.push('1800')	# sha512crypt, SHA512(Unix)
  elsif hash =~ %r{^[\.\/0-9A-Za-z]{13}$}
    @modes.push('1500')	# descrypt, DES(Unix), Traditional DES
  elsif hash =~ /^[^\\\/:*?"<>|]{1,20}[:]{2,3}[^\\\/:*?"<>|]{1,20}?:[a-f0-9]{48}:[a-f0-9]{48}:[a-f0-9]{16}$/i
    @modes.push('5500')	# NetNTLMv1-VANILLA / NetNTLMv1+ESS
  elsif hash =~ /^[^\\\/:*?"<>|]{1,20}\\?[^\\\/:*?"<>|]{1,20}[:]{2,3}[^\\\/:*?"<>|]{1,20}:?[^\\\/:*?"<>|]{1,20}:[a-f0-9]{32}:[a-f0-9]+$/i
    @modes.push('5600')	# NetNTLMv2
  elsif hash =~ /^\$P\$/
    @modes.push('400')  # phppass, WordPress(MD5), Joomla (MD5)
  elsif hash =~ /^\$H\$/
    @modes.push('400')  # phppass, phpBB3 (MD5)
  elsif hash =~ /^[\+\/\=0-9A-Za-z]+$/
    @modes.push('501')  # Juniper IVE
  elsif hash =~ /^\$BLAKE2\$/
    @modes.push('600')  # Blake2b-512
  elsif hash =~ /^([^\\\/:*?"<>|]{1,20}:)?[a-f0-9]{32}(:[^\\\/:*?"<>|]{1,20})?$/
    @modes.push('1100') # Domain Cached Credentials (DCC), MS Cache
  elsif hash =~ /^[0-9a-fA-F]{56}$/
    @modes.push('1300') # SHA-224
  elsif hash =~ /^[a-f0-9]{64}(:.+)?$/
    @modes.push('1400') # SHA-256
    @modes.push('1410') # sha256($pass.$salt)
    @modes.push('1420') # sha256($salt.$pass)
    @modes.push('1430') # sha256(unicode($pass).$salt)
    @modes.push('1440') # sha256($salt.unicode($pass))
    @modes.push('1450') # HMAC-SHA256 (key = $pass)
    @modes.push('1460') # HMAC-SHA256 (key = $salt)
    @modes.push('5000') # SHA-3 (Keccak)
    @modes.push('6900') # GOST R 34.11-94
  elsif hash =~ /^\$apr1\$[a-z0-9\/.]{0,8}\$[a-z0-9\/.]{22}$/
    @modes.push('1600') # Apache $apr1 MD5, md5apr1, MD5(ARP)
  elsif hash =~ /^[a-f0-9]{128}(:.+)?$/
    @modes.push('1700') # SHA-512
    @modes.push('1710') # sha512($pass.$salt)
    @modes.push('1720') # sha512($salt.$pass)
    @modes.push('1730') # sha512(unicode($pass).$salt)
    @modes.push('1740') # sha512($salt.unicode($pass))
    @modes.push('1750') # HMAC-SHA512 (key = $pass)
    @modes.push('1760') # HMAC-SHA512 (key = $salt)
    @modes.push('6100') # Whirlpool
  elsif hash =~ /^[a-z0-9\/.]{16}$/
    @modes.push('2400') # Cisco-PIX MD5
  elsif hash =~ /^[a-z0-9\/.]{16}([:$].{1,})?$/
    @modes.push('2410') # Cisco-ASA MD5
  elsif hash =~ /^(\$chap\$0\*)?[a-f0-9]{32}[\*:][a-f0-9]{32}(:[0-9]{2})?$/
    @modes.push('4800') # iSCSI CHAP authentication, MD5(CHAP)
  elsif hash =~ /^[a-z0-9]{43}$/
    @modes.push('5700') # Cisco-IOS type 4 (SHA256)
  elsif hash =~ /^[a-f0-9]{40}:[a-f0-9]{16}$/
    @modes.push('5800') # Samsung Android Password/PIN
  elsif hash =~ /^{smd5}[a-z0-9$\/.]{31}$/
    @modes.push('6300') # AIX {smd5}
  elsif hash =~ /^{ssha256}[0-9]{2}\$[a-z0-9$\/.]{60}$/
    @modes.push('6400') # AIX {ssha256}
  elsif hash =~ /^{ssha512}[0-9]{2}\$[a-z0-9\/.]{16,48}\$[a-z0-9\/.]{86}$/
    @modes.push('6500') # AIX {ssha512}
  elsif hash =~ /^{ssha1}[0-9]{2}\$[a-z0-9$\/.]{44}$/
    @modes.push('6700') # AIX {ssha1}
  # elsif hash =~ /^[0-9]{4}:[a-f0-9]{16}:[a-f0-9]{2080}$/
  #  @modes.push('6800') # LastPass + LastPass sniffed
  elsif hash =~ /^[a-z0-9=]{47}$/
    @modes.push('7000') # FortiGate (FortiOS)
  elsif hash =~ /^\$ml\$[0-9]+\$[a-f0-9]{64}\$[a-f0-9]{128}$/
    @modes.push('7100') # OSX v10.8+ (PBKDF2-SHA512)
  elsif hash =~ /^grub\.pbkdf2\.sha512\.[0-9]+\.([a-f0-9]{128,2048}\.|[0-9]+\.)?[a-f0-9]{128}$/
    @modes.push('7200') # Grub 2
  elsif hash =~ /^[a-f0-9]{130}(:[a-f0-9]{40})?$/
    @modes.push('7300') # IPMI2 RAKP HMAC-SHA1
  elsif hash =~ /^\$S\$[a-z0-9\/.]{52}$/
    @modes.push('7900') # Drupal7
  elsif hash =~ /^0x[a-f0-9]{4}[a-f0-9]{16}[a-f0-9]{64}$/
    @modes.push('8000') # Sybase ASE
  elsif hash =~ /^[a-f0-9]{49}$/
    @modes.push('8100') # Citrix NetScaler
  elsif hash =~ /^[a-z0-9]{32}(:([a-z0-9-]+\.)?[a-z0-9-.]+\.[a-z]{2,7}:.+:[0-9]+)?$/
    @modes.push('8300') # DNSSEC (NSEC3)
  elsif hash =~ /^(\$wbb3\$\*1\*)?[a-f0-9]{40}[:*][a-f0-9]{40}$/
    @modes.push('8400') # WBB3 (Woltlab Burning Board)
  elsif hash =~ /^\([a-z0-9\/+]{20}\)$/
    @modes.push('8700') # Lotus Notes/Domino 5
  elsif hash =~ /^SCRYPT:[0-9]{1,}:[0-9]{1}:[0-9]{1}:[a-z0-9:\/+=]{1,}$/
    @modes.push('8900') # script
  elsif hash =~ /^\([a-z0-9\/+]{49}\)$/
    @modes.push('9100') # Lotus Notes/Domino 8
  else
    @modes.push('99999') # UNKNOWN (plaintext)
  end
end

# Called by search
def modeToFriendly(mode)
  return 'MD5' if mode == '0'
  return 'md5($pass.$salt)' if mode == '10'
  return 'md5($salt.$pass)' if mode == '20'
  return 'md5(unicode($pass).$salt)' if mode == '30'
  return 'md5($salt.unicode($pass))' if mode == '40'
  return 'HMAC-MD5 (key = $pass)' if mode == '50'
  return 'HMAC-MD5 (key = $salt)' if mode == '60'
  return 'SHA-1' if mode == '100'
  return 'sha1($pass.$salt)' if mode == '110'
  return 'sha1($salt.$pass)' if mode == '120'
  return 'sha1(unicode($pass).$salt)' if mode == '130'
  return 'sha1($salt.unicode($pass))' if mode == '140'
  return 'HMAC-SHA1 (key = $pass)' if mode == '150'
  return 'HMAC-SHA1 (key = $salt)' if mode == '160'
  # return 'sha1(LinkedIn)' if mode == '190'
  return 'MySQL323' if mode == '200'
  return 'md5crypt' if mode == '500'
  return 'MD4' if mode == '900'
  return 'NTLM' if mode == '1000'
  return 'descrypt' if mode == '1500'
  return 'sha512crypt' if mode == '1800'
  return 'Double MD5' if mode == '2600'
  return 'LM' if mode == '3000'
  return 'Oracle 7-10g, DES(Oracle)' if mode == '3100'
  return 'bcrypt' if mode == '3200'
  return 'md5(md5(md5($pass)))' if mode == '3500'
  return 'md5(md5($salt).$pass)' if mode == '3610'
  return 'md5($salt.md5($pass))' if mode == '3710'
  return 'md5($pass.md5($salt))' if mode == '3720'
  return 'md5(md5($pass).md5($salt))' if mode == '3910'
  return 'md5($salt.md5($salt.$pass))' if mode == '4010'
  return 'md5($salt.md5($pass.$salt))' if mode == '4110'
  return 'md5(strtroupper(md5($pass)))' if mode == '4300'
  return 'md5(sha1($pass))' if mode == '4400'
  return 'sha1(sha1($pass))' if mode == '4500'
  return 'sha1(sha1(sha1($pass)))' if mode == '4600'
  return 'sha1(md5($pass))' if mode == '4700'
  return 'Half MD5' if mode == '5100'
  return 'NetNTLMv1' if mode == '5500'
  return 'NetNTLMv2' if mode == '5600'
  return 'RipeMD160' if mode == '6000'
  return 'sha256crypt' if mode == '7400'
  return 'Lotus Notes/Domino 5' if mode == '8600'
  return 'PrestaShop' if mode == '11000'
  return 'unknown' if mode == '99999'
  return 'unknown'
end

def friendlyToMode(friendly)
  return '0' if friendly == 'MD5'
  return '1000' if friendly == 'NTLM'
  return '3000' if friendly == 'LM'
  return '100' if friendly == 'SHA-1'
  return '500' if friendly == 'md5crypt'
  return '3200' if friendly == 'bcrypt'
  return '7400' if friendly == 'sha512crypt'
  return '1800' if friendly == 'sha256crypt'
  return '1500' if friendly == 'descrypt'
  return '5500' if friendly == 'NetNTLMv1'
  return '5600' if friendly == 'NetNTLMv2'
end

def importHash(hash_file, hashfile_id, file_type, hashtype)

  @hashes = NBDB[:hashes]
  @hashfilehashes = NBDB[:hashfilehashes]

  hash_file.each do |entry|
    entry = entry.gsub(/\s+/, '') # remove all spaces
    if file_type == 'pwdump' or file_type == 'smart hashdump' 
      importPwdump(entry.chomp, hashfile_id, hashtype) #because the format is the same aside from the trailing ::
    elsif file_type == 'shadow'
      importShadow(entry.chomp, hashfile_id, hashtype)
    elsif file_type == 'hash_only'
      importHashOnly(entry.chomp, hashfile_id, hashtype)
    elsif file_type == 'dsusers'
      importDsusers(entry.chomp, hashfile_id, hashtype)
    elsif file_type == 'user_hash'
      importUserHash(entry.chomp, hashfile_id, hashtype)
    elsif file_type == 'hash_salt'
      importHashSalt(entry.chomp, hashfile_id, hashtype)
    elsif file_type == 'NetNTLMv1'
      importNetNTLMv1(entry.chomp, hashfile_id, hashtype)
    elsif file_type == 'NetNTLMv2'
      importNetNTLMv2(entry.chomp, hashfile_id, hashtype)
    else
      return 'Unsupported hash format detected'
    end
  end
end

#def detectHashfileType(hash_file)
#  @file_types = []
#  File.readlines(hash_file).each do |entry|
#    entry = entry.gsub(/\s+/, "") # remove all spaces
#    if detectedHashFormat(entry.chomp) == 'pwdump'
#      @file_types.push('pwdump') unless @file_types.include?('pwdump')
#    elsif detectedHashFormat(entry.chomp) == 'shadow'
#      @file_types.push('shadow') unless @file_types.include?('shadow')
#    elsif detectedHashFormat(entry.chomp) == 'dsusers'
#      @file_types.push('dsusers') unless @file_types.include?('dsusers')
#    elsif detectedHashFormat(entry.chomp) == 'generic'
#      @file_types.push('generic') unless @file_types.include?('generic')
#    elsif detectedHashFormat(entry.chomp) == 'smart hashdump'
#      @file_types.push('smart hashdump') unless @file_types.include?('smart hashdump')
#    else
#      @file_types.push('raw') unless @file_types.include?('raw')
#    end
#  end

#  @file_types
#end

def detectHashType(hash_file, file_type)
  @hashtypes = []
  File.readlines(hash_file).each do |entry|
    entry = entry.gsub(/\s+/, "") # remove all spaces
    if file_type == 'pwdump' or file_type == 'smart_hashdump'
      elements = entry.split(':')
      @modes = getMode(elements[2])
      @modes.each do |mode|
        @hashtypes.push(mode) unless @hashtypes.include?(mode) # LM
      end
      @modes = getMode(elements[3])
      @modes.each do |mode|
        @hashtypes.push(mode) unless @hashtypes.include?(mode) # NTLM
      end
    elsif file_type == 'shadow' || file_type == 'dsusers' || file_type == 'user_hash'
      elements = entry.split(':')
      @modes = getMode(elements[1])
      @modes.each do |mode|
        @hashtypes.push(mode) unless @hashtypes.include?(mode)
      end
    else
      @modes = getMode(entry)
      @modes.each do |mode|
        @hashtypes.push(mode) unless @hashtypes.include?(mode)
      end
    end
  end
  @hashtypes
end
