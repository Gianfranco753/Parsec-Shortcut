=Download=
Little program to automate Wake on LAN and [Parsec](https://parsec.tv/) client start.

==Downloads==
[Download WoLParsec](build/WakeParsec.exe)
[Download Opener](build/Opener.exe)

==Description==
This program is divided in 2 programs, WolParsec and the Opener (optional).

===WoLParsec===
The objetive of this program is to allow a shortcut in your parsec client to wake up the parsec server and connect to it automatically. If the Opener is running in the server, it will also open the program.
When you run the program, it will ask the server name, ip and Mac address, besides your parsec email and password and some timeouts (because without the timeouts, the program will wait forever if the server fails to wake up).
Then all the data is saved to Config. Ini, and the program pint the server, if there is no response, send a WoL magic package and wait until the server is awake or the timeout is reached.
Next, the program login the user in parsec.tv (Only on first run, next runs will remain login) and get the servers list.
Then with all this data, the program construct a special url that the warp parsec client recognice and launch the server that you configurate in the beginning (with the server name).
All the sensible data (password, cookies,etc) is stored encrypted in the config.ini file.

===Opener===
Open programs in a Parsec server. Needs WoLParsec to work.


This program is written in [Autoit v3](https://www.autoitscript.com/).
The loading bar was coded by UEZ of the [Autoit forum](https://www.autoitscript.com/forum/topic/150545-gdi-animated-loading-screens-build-2014-06-20-32-examples/) with an idea taken from http://www.alessioatzeni.com/wp-content/tutorials/html-css/CSS3-Loading-Animation/index.html
