Shell script that simplifies the setup process for webpack projects - you can immediately start coding instead of spending hours fiddling with config files only to find nothing works because you accidentally installed "dev-server" instead of "devserver" (true story). 

Run the script from the terminal with `./webpack_init.sh` and provide a file path for the project to be created (e.g. `./webpack_init.sh /some-drive/some-folder/my-cool-project`).
It will then run through all the usuall install scripts depending on what you select to be installed. 
Once it is done you should be able to run `npm run dev` for the devserver and `npm run build` to build the project - and immediately start coding!

I am by no means much good at bash so there are probably bugs. Works on windows with MINGW64 and the GNU programs but not Mac OS - it complains about some of the commands in the script. Probably as Mac OS uses the FreeBSD command line tools instead of the GNU versions?

Installs webpack and common plugins:
- html-webpack-plugin
- css and style loaders
- devserver
- eslint
- prettier

And create and configure any config files for the plugins to work together properly (i.e. eslint and prettier). 
