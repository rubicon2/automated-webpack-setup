#!/bin/bash

# $1 = path to directory that needs setting up
DIRECTORY=$1

# call script with directory path as arg 1. Access with $1
if [ -z "$DIRECTORY" ] 
then
	echo "Run script with desired directory path as an argument!"
	exit 0
fi

cd $DIRECTORY

# do some argument checking later to avoid any weird errors if neither y or n
read -p "Using html-webpack-plugin? y/n " html
read -p "Using css and style loaders? y/n " css_loader
read -p "Using devserver? y/n " dev_server
read -p "Using eslint? (if yes, choose js as the config file format) y/n " eslint
read -p "Using prettier? y/n " prettier

# new line
echo 

# initialise npm
echo "Initializing npm files..."
echo "Leave test blank - this will be overwritten later"
npm init
echo "npm initialized."
echo

# initialise webpack
echo "Installing webpack..."
echo "Installing webpack-cli..."
echo "Installing webpack-merge..."
npm install -D webpack webpack-cli webpack-merge
echo
echo "webpack installed."
echo "webpack-cli installed."
echo "webpack-merge installed."
echo
echo "Creating webpack config files..."
touch webpack.common.js
touch webpack.prod.js
echo "webpack config files created."
echo 

echo "Creating .gitignore file..."
echo "*.DS_Store" > .gitignore
echo "/node_modules" >> .gitignore
echo ".gitignore created."
echo

# create directories
mkdir src dist

# install all the desired plugins
if [[ "$html" =~ [^nN] ]]; then
	echo "Installing html-webpack-plugin..."
	npm install -D html-webpack-plugin
	echo
	echo "html-webpack-plugin installed."
	echo
fi

if [[ "$css_loader" =~ [^nN] ]]; then
	echo "Installing css-loader..."
	echo "Installing style-loader..."
	npm install -D css-loader style-loader
	echo
	echo "css-loader installed."
	echo "style-loader installed."
	echo
fi

if [[ "$dev_server" =~ [^nN] ]]; then
	echo "Installing webpack-dev-server..."
	npm install -D webpack-dev-server
	echo
	echo "webpack-dev-server installed."
	echo

	echo "Creating webpack.dev.js config file..."
	touch webpack.dev.js
	echo 'const { merge } = require("webpack-merge");
const common = require("./webpack.common");

module.exports = merge(common, {
	mode: "development",
	devtool: "inline-source-map",
	devServer: {
		static: "./dist",
	},
});' >> webpack.dev.js
	echo "webpack.dev.js configured."
fi

if [[ "$eslint" =~ [^nN] ]]; then
	echo "Installing eslint..."
	echo "NodeJS bug may render eslint config arrow key input impossible."
	echo "If this is the case, type a number to select an option. Options start from zero."
	npm init @eslint/config
	echo
	echo "eslint installed and configured."
	echo
fi

if [[ "$prettier" =~ [^nN] ]]; then

	echo "Installing prettier..."
	npm install -D --save-exact prettier
	echo
	echo "prettier installed."
	echo "Creating prettier config files..."

	echo { > .prettierrc.json
	echo \"trailingComma\": \"es5\", >> .prettierrc.json
	echo \"tabWidth\": 4, >> .prettierrc.json
	echo \"semi\": true, >> .prettierrc.json
	echo \"singleQuote\": true >> .prettierrc.json
	echo } >> .prettierrc.json

	# format the file nicely
	npx prettier --write .prettierrc.json

	echo ".prettierrc.json created."

	cp .gitignore .prettierignore
	echo "/dist" >> .prettierignore

	echo ".prettierignore created, based off .gitignore."

	echo "prettier config files created."

	# need to edit eslint config file to work with prettier
	if [[ "$eslint" =~ [^nN] ]]; then
		
		echo "Installing eslint-config-prettier..."
		npm install -D eslint-config-prettier
		echo
		echo "eslint-config-prettier installed."

		# if there are square brackets
		if grep -E -q '"?extends"?: \[' .eslintrc.js; then

			echo 'Format is extends with []!'

			# get line numbers
			line=$(awk '/extends/,/]/ {print NR" "$0}' .eslintrc.js | tail -n 1 | awk '{print $1}')
			previous_line=$(($line-1))

			# add a comma to the previous line if there isn't one already
			sed -i $previous_line's/[^,]$/&,/' .eslintrc.js
			sed -i $line'i\"prettier"' .eslintrc.js

		# if there are no square brackets
		elif grep -E -q '"?extends"?: [^\[]' .eslintrc.js; then

			echo 'Format is extends with no []! Add square brackets!'

			existing_extension=$(awk '/extends[^\n]+,$/ {print $2}' .eslintrc.js)

			# add opening square bracket and remove existing extension from line
			if grep -q '"' .eslintrc.js; then
				sed -i 's/"extends":/& \[\n/' .eslintrc.js
			else 
				sed -i 's/extends:/& \[\n/' .eslintrc.js
			fi

			# add back in existing extension on one line, followed by \n "prettier", followed by \n ],
			sed -i 's/'$existing_extension'/&\n"prettier"\n\],/' .eslintrc.js

		# giving a synax error near "unexpected token 'else'" ?
		else 
			echo 'extends does not exist! Adding to file...'
			# only one should execute depending on format of file
			sed -i '/"overrides":/i\"extends": "prettier",' .eslintrc.js
			sed -i '/overrides:/i\extends: "prettier",' .eslintrc.js
		fi

		npx prettier --write .eslintrc.js	
		echo ".eslintrc.js updated to use prettier"
	fi

	echo
fi

# update package.json: replace default "test" with devserver and build commands
if [[  "$dev_server" =~ [^nN] ]]; then
	sed -i 's/"test"[^\n]*$/"dev": "webpack-dev-server --open --config webpack.dev.js",/' package.json
	sed -i '/"dev"/a\"build": "webpack --config webpack.prod.js"' package.json
else
	sed -i 's/"test"[^\n]*$/"build": "webpack --config webpack.prod.js"/' package.json
fi

echo "using prettier to clean up edited package.json file..."
npx prettier --write package.json
echo

# awk entry point from package.json and remove comma at end of line
js_entry=$(awk '/main/ {print $2}' package.json | sed 's/,//; s/"//g')

# create basic entry file
touch ./src/"$js_entry"
if [[ "$css_loader" =~ [^nN] ]]; then
	touch ./src/style.css
	echo 'import "./style.css";' > ./src/"$js_entry" 
fi

echo 'module.exports = {
	entry: {
		main: "./src/'"$js_entry"'",
	},
	module: {
		rules: [
			{
				test: /\.(jpg|jpeg|png|gif|svg|bmp)$/i,
				type: "asset/resource",
			},
			{
				test: /\.(woff|woff2|ttf)$/i,
				type: "asset/resource",
			},' > webpack.common.js

if [[ "$css_loader" =~ [^nN] ]]; then
	# add to webpack.common.js rules: []
	echo '			{
				test: /\.css$/i,
				use: ["style-loader", "css-loader"],
			},' >> webpack.common.js
fi

# finish off the module key value pair
echo '		],
	},' >> webpack.common.js

if [[ "$html" =~ [^nN] ]]; then
	sed -i '1i\const HtmlWebpackPlugin = require("html-webpack-plugin");' webpack.common.js
	sed -i '2i\\n' webpack.common.js
	# this needs to be inserted after module {},
	echo '	plugins: [
		new HtmlWebpackPlugin({
			title: "Automated Webpack Setup Project"
		}),
	],' >> webpack.common.js
fi

echo '}' >> webpack.common.js

echo 'const path = require("path");
const { merge } = require("webpack-merge");
const common = require("./webpack.common");

module.exports = merge(common, {
	mode: "production",
	output: {
		filename: "[name].bundle.js",
		path: path.resolve(__dirname, "dist"),
		clean: true,
	},
});' >> webpack.prod.js

# display avilable npm scripts, i.e. dev or build
npm run
echo

echo "Setup complete. Now get started on your project!"

