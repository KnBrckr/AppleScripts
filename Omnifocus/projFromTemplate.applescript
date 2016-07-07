app = Application.currentApplication();
app.includeStandardAdditions = true;
OF = Application('OmniFocus');

// Select input file and retrieve contents

file = app.chooseFile({
	withPrompt:"Select Omnifocus Template",
	ofType:"public.text"
	});
contents = app.read(file, {usingDelimiter:'\n'});

// 

var templateVars = {}; // Associative array of text variables

for (var i = 0 ; i < contents.length ; i++) {
	if (contents[i].startsWith('$')) {
		// Grab variables to be used for later substitution in text
		parts = contents[i].split('=');
		varname = parts[0].trim();
		values = parts[1].split(',').map(function(s) { return s.trim() });
		templateVars[varname] = values;
	} else {
		parseLine(contents[i]);
	}	
}

function parseLine(line) {
	var lineVars = line.match(/\${[^}]*}/g); // Look for variables to replace
	
	if (lineVars == null) {
		// If no variables found, send to Omnifocus for parsing
		console.log(line);
		return;
	} else {
		// Replace first variable and recurse
		var cleanName = lineVars[0].replace(/[{}]/g,'');
		if (templateVars[cleanName]) {
			for (var i = 0 ; i < templateVars[cleanName].length ; i++) {
				parseLine(line.replace(lineVars[0], templateVars[cleanName][i]));
			}
		}
	}
}

// on parse(transportText)
//	parse tasks into default document with transport text transportText
// end parse