require 'filewatcher'
require 'FileUtils'
require 'SQLite3'
require 'yaml'
require 'Logger'

# AW - 23.02.2015
# Tool for copying pdfs from subfolders to a folder.

# Simply delete the database file if you want to reset the files.
# Note: This script does overwrite existing files in the destination folder.

def read_config
	config = YAML.load_file("config.yaml")
	@databaseFile = config["databaseFile"]
	@sourceFiles = config["sourceFiles"]
	@destination_directory = config["destination_directory"]
	@checkTimeForThread = config["checkTimeForThread"]
	@logfilePath = config["logfile"]
	@loglevel = config["loglevel"]
end

def checkForNewFilesAtBeginning 
	# create the database if it doesn't exist
	if not File.exists?@databaseFile
		@logger.info("trying to create database: " + @databaseFile)
		db = SQLite3::Database.new( @databaseFile )
		db.execute("CREATE TABLE files (filename   STRING (255) PRIMARY KEY, date_added DATETIME, copied BOOLEAN  DEFAULT false);")
	end

	SQLite3::Database.new( @databaseFile ) do |db|
		databaseFiles = []
		db.results_as_hash = true

		Dir[@sourceFiles].each do |file|
			basename = File.basename file
			databaseFile = db.get_first_value("select filename from files where filename = '#{basename}'")
			@logger.debug(file)

			# if file is not in the db => copy the file
			if not databaseFile.eql?(basename)
				@logger.info("copied file: " + file)
				copyFile(file)
			end
		end
	end
end

def copyFile(file_path) 
	basename = File.basename file_path # Just the filename without path
	#if(Dir[destination_directory + basename].length > 0) # only copy if file doesn't exist yet. To avoid problems with permissions
		begin 
		FileUtils.cp(file_path, @destination_directory) # source to destination
		rescue SystemCallError
			@logger.error("Error writing " +  @destination_directory + basename)
		end
	#end

	addFileToDatabase(basename)
end

def addFileToDatabase(filename)
	date_added = Time.now
	copied = true
	SQLite3::Database.new(@databaseFile) do |db|
		@logger.info("add file to db: " + filename)
		db.execute( "INSERT INTO files ( filename, date_added, copied ) VALUES ('#{filename}', '#{date_added}', '#{copied}' )" )
	end
end

def watchForNewFiles 
	FileWatcher.new(@sourceFiles).watch do |filename, event|
	  if(event == :new)
	    @logger.info("File was added to source folder: " + filename)

	    Thread.new (filename) {|filename|
	    	Kernel.sleep 10 # sleep for 10 seconds to make sure that fuji wrote the whole file and
	    			 # that the lock on the file was closed. Also, I don't want to block the main thread.
	    	copyFile(filename)
	    }
	  end
	end
end

puts "CopyTool"

read_config()
@logger = Logger.new(@logfilePath, 'daily')
@logger.level = @loglevel
@logger.info("CopyTool was started")

checkForNewFilesAtBeginning()

# Start a thread for always looking for new files. 
filewatching = Thread.new {
	watchForNewFiles()
}

 loop do
      begin
        Kernel.sleep @checkTimeForThread # this means that it sleeps x seconds until checking if thread still alive
      rescue SystemExit,Interrupt # end programm on interrupt/shutdown, maybe notify someone about a problem
        @logger.error("CopyTool will exit because of interrupt or a shutdown")
        Kernel.exit
      end
      @logger.debug("Copytool: making sure that the FileWatching thread is still alive")
      if not filewatching.alive?
      	@logger.info("Copytool: Restarting the FileWatching Thread")
      	filewatching.start #restart thread
      end
    end