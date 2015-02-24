# CopyTool Documentation
## Features

A tool which watches a folder for new files in which are added and then copies the new file to a folder. Has a database to remember copied files. It was created to copy *.pdf files from subfolder into one unified inbox folder. If a file was copied once, then it won't be copied again.


## How to use:
Run: 
```
gem install SQLite3
ruby pdf_kopiertool.rb
```

See config.yaml for more information on how to set the source and the target folder.

You just have to change those paths. They can be absolute or relative: 
sourceFiles: "workflow/*/*.pdf"
destination_directory: "ziel/"

## How to compile:
Don't forget to install the gem SQLLite3

Then run the commands below or download ocra from https://github.com/larsch/ocra/releases

Ocra will run the file and you need to stop it using ctrl + c to finish the compilation.

The flag --windows means that the tool will not show an window and run in the background.

```
gem install ocra
ocra --windows pdf_kopiertool.rb 
```


Licenced under the MIT Licence.
The bundled Filewatcher.rb code is from https://github.com/thomasfl/filewatcher/
Copyright (c) 2011 - 2015 Thomas Flemming. See LICENSE for details.