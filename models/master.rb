require 'rubygems'
require 'data_mapper'
require 'bcrypt'
require 'sequel'

# read config
options = YAML.load_file('config/database.yml')

# there has to be a better way to handle this shit
if ENV['RACK_ENV'] == 'test'
  DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, options['test'])
  NBDB = Sequel.mysql(options['test'])
elsif ENV['RACK_ENV'] == 'development'
  DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, options['development'])
elsif ENV['RACK_ENV'] == ('production' || 'default')
  DataMapper.setup(:default, options['production'])
else
  puts 'ERROR: You must define an evironment. ex: RACK_ENV=production'
  exit
end

# User class object to handle user account credentials
class User
  include DataMapper::Resource

  property :id, Serial
  property :username, String, key: true, length: (3..40), required: true
  property :hashed_password, String, length: 128
  property :admin, Boolean
  property :created_at, DateTime, default: DateTime.now
  property :phone, String, required: false
  property :email, String, required: false

  attr_accessor :password
  validates_presence_of :username

  def password=(pass)
    @password = pass
    self.hashed_password = User.encrypt(@password)
  end

  def self.encrypt(pass)
    BCrypt::Password.create(pass)
  end

  def self.authenticate(username, pass)
    user = User.first(username: username)
    if user
      return user.username if BCrypt::Password.new(user.hashed_password) == pass
    end
  end

  def self.create_test_user(attrs = {})
    user = User.new(
      username: 'test',
      admin: true,
      phone: '12223334444',
      email: 'test@localhost.com',
      hashed_password: BCrypt::Password.create('omgplains')
    )
    user.save
    user.update(attrs) if attrs
    user.save
    return user.id
  end

  def self.delete_test_user(id)
    user = User.first(id: id)
    user.destroy
  end

  def self.delete_all_users()
    @users = User.all
    @users.destroy
  end

end

# Class to handle authenticated sessions
class Sessions
  include DataMapper::Resource

  property :id, Serial
  property :session_key, String, length: 128
  property :username, String, length: (3..40), required: true

  def self.isValid?(session_key)
    sessions = Sessions.first(session_key: session_key)

    return true if sessions
  end

  def self.type(session_key)
    sess = Sessions.first(session_key: session_key)

    if sess
      if User.first(username: sess.username).admin
        return TRUE
      else
        return FALSE
      end
    end
  end

  def self.getUsername(session_key)
    sess = Sessions.first(session_key: session_key)

    return sess.username if sess
  end
end

# Each Customer record will be stored here
class Customers
  include DataMapper::Resource
  property :id, Serial
  property :name, String, length: 40
  property :description, String, length: 500
end

class Agents
  include DataMapper::Resource
  property :id, Serial
  property :name, String, length: 100
  property :src_ip, String, length: 45
  property :uuid, String, length: 60
  # status can be Pending, Authorized, Error, Offline, Online, Working
  property :status, String, length: 40
  property :hc_status, String, length: 6000
  property :heartbeat, DateTime
  property :benchmark, String, length: 6000
  property :devices, String, length: 6000
  property :cpu_count, Integer
  property :gpu_count, Integer
end

# Each job generated by user will be stored here
class Jobs
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :last_updated_by, String, length: 40
  property :updated_at, DateTime, default: DateTime.now
  # status options should be "Running", "Paused", "Completed", "Queued", "Canceled", "Ready"
  property :status, String, length: 100
  property :queued_at, DateTime
  property :targettype, String, length: 2000
  property :hashfile_id, Integer
  property :policy_min_pass_length, Integer
  property :policy_complexity_default, Boolean
  property :customer_id, Integer
  property :notify_completed, Boolean
end

# Jobs will have multiple crack tasks
class Jobtasks
  include DataMapper::Resource

  property :id, Serial
  property :job_id, Integer
  property :task_id, Integer
  property :build_cmd, String, length: 5000
  # status options should be "Running", "Paused", "Not Started", "Completed", "Queued", "Failed", "Canceled", "Importing"
  property :status, String
  property :run_time, Integer
end

# Task definitions
class Tasks
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :source, String
  property :mask, String
  property :command, String, length: 4000
  property :wl_id, String, length: 256
  property :hc_attackmode, String, length: 25
  property :hc_rule, String
  property :hc_mask, String
  # support huge keyspaces
  property :keyspace, Integer, max: 9999999999999999999
end

# Table for handling hashes cracked and uncracked
class Hashes
  include DataMapper::Resource

  property :id, Serial
  property :lastupdated, DateTime
  property :originalhash, String, length: 1024, :unique_index => true
  property :hashtype, Integer, :index => true
  property :cracked, Boolean
  property :plaintext, String, length: 255
end

# Table for managing association between users and hashes
class Hashfilehashes
  include DataMapper::Resource

  property :id,	Serial
  property :hash_id, Integer, :index => true
  property :username, String, length: 256
  property :hashfile_id, Integer, :index => true
end

# User Settings
class Settings
  include DataMapper::Resource

  property :id, Serial
  property :smtp_server, String
  property :smtp_sender, String, length: 50
  property :smtp_user, String
  property :smtp_pass, String
  property :smtp_use_tls, Boolean
  property :smtp_auth_type, String # Options are plain, login, cram_md5, none
  property :clientmode, Boolean
  property :ui_themes, String, default: 'Light', required: true
  property :version, String, length: 5
  property :chunk_size, Integer, max: 9999999999999999999, default: 500000
end

# HashCat settings
class HashcatSettings
  include DataMapper::Resource

  property :id, Serial
  property :hc_binpath, String, length: 2000
  property :max_task_time, String, length: 2000
  property :opencl_device_types, Integer, default: 0
  property :workload_profile, Integer, default: 0
  property :gpu_temp_disable, Boolean, default: 0
  property :gpu_temp_abort, Integer, default: 0
  property :gpu_temp_retain, Integer, default: 0
  property :hc_force, Boolean, default: 0
end

# Hashview Hub Settings
class HubSettings
  include DataMapper::Resource

  property :id, Serial
  property :enabled, Boolean
  property :status, String, default: 'unregistered', required: true # Options are registered, unregistered and pending
  property :email, String
  property :uuid, String
  property :auth_key, String, length: 254
  property :balance, Integer, default: 0
end


# Wordlist Class
class Wordlists
  include DataMapper::Resource

  property :id, Serial
  property :lastupdated, DateTime
  property :type, String, length: 25 # Options are Static or Dynamic
  property :name, String, length: 256
  property :path, String, length: 2000
  property :size, String, length: 100
  property :checksum, String, length: 64

end

# Rules Class
class Rules
  include DataMapper::Resource

  property :id, Serial
  property :lastupdated, DateTime
  property :name, String, length: 256
  property :path, String, length: 2000
  property :size, String, length: 100
  property :checksum, String, length: 64

end

# Hashfile Class
class Hashfiles
  include DataMapper::Resource

  property :id, Serial
  property :customer_id, Integer
  property :name, String, length: 256
  property :hash_str, String, length: 256
  property :total_run_time, Integer, default: 0
end

# task queue (we no logger use a resque worker)
class Taskqueues
  include DataMapper::Resource

  property :id, Serial
  property :jobtask_id, Integer
  property :job_id, Integer
  property :updated_at, DateTime, default: DateTime.now
  # status options should be "Running", "Completed", "Queued", "Canceled", "Paused"
  property :queued_at, DateTime
  property :status, String, length: 100
  property :agent_id, String, length: 2000
  property :command, String, length: 4000
end

DataMapper.finalize
