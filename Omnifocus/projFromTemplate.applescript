/**
 * Create Omnifocus tasks based on input template file
 * Format of file:
 
$team = test1, test2, test 3
$stuff = something interesting
$project = Test Project
Do something @focus ::${project} #5pm #tomorrow //Note
Do another thing @focus ::${project}
    subtask1 of ${stuff} @${team} ::${project}
    subtask2 @${team} ::${project}
Main task ${undef} @test1 ::${project}
 */

app = Application.currentApplication();
app.includeStandardAdditions = true;
OF = Application('OmniFocus');
OFdoc = OF.defaultDocument
/* debugger */

// Select input file and retrieve contents

template = app.chooseFile({
	withPrompt:"Select Omnifocus Template",
	ofType:"public.text"
	});
templateContents = app.read(template, {usingDelimiter:'\n'});
/*
*/

// Process each line of the template file

var templateVars = {}; // Associative array of text variables
var newTasks = []; // Array of new tasks to be created

for (var i = 0 ; i < templateContents.length ; i++) {
	if (templateContents[i].trim().match(/^\$\w+\s*=/) != null) {
		// Grab variables to be used for later substitution in text
		parts = templateContents[i].split('=');
		varname = parts[0].trim();
		values = parts[1].split(',').map(function(s) { return s.trim() });
		templateVars[varname] = values;
	} else {
		replaceVars(templateContents[i]);
	}	
}

// TODO Build nested project tree, create undefined project
for (var i = 0 ; i < newTasks.length ; i++) {
	OFparse(newTasks[i]);
}

/**
 * Replace first variable of form ${var} with single value or array of values, recurse to replace all variables
 * @method replaceVars
 * @param {string} string - string to operate on
 * @global {associative array} templateVars - Array of variable names => array of replacement strings
 * @global {array of strings} newTasks - Array of task names with variables replaced
 * @return null
 */
function replaceVars(string) {
	var stringVars = string.match(/\${[^}]*}/g); // Look for variables to replace
	
	if (stringVars == null) {
		// If no variables found, add to task list
		newTasks.push(string);
	} else {
		// Replace first variable in the string and recurse
		var cleanName = stringVars[0].replace(/[{}]/g,'');
		if (templateVars[cleanName]) {
			var stringArray = [];
			for (var i = 0 ; i < templateVars[cleanName].length ; i++) {
				replaceVars(replace(string, stringVars[0], templateVars[cleanName][i]));
			}
		} else {
			replaceVars(replace(string, stringVars[0], "undefined"));
			// TODO When template file does not define a variable, prompt via dialog
		}
	}
}

/**
 * Replace all instances of a substring in a string
 * @method replace
 * @param {string} string - string to operate on
 * @param {string} oldStr - substring to replace
 * @param {string} newStr - replacement substring
 * @return {string} updated string
 */
function replace(string, oldStr, newStr) {
	while (string.includes(oldStr)) {
		string = string.replace(oldStr, newStr);
	}
	return string;
}

/**
 * Prase creates a new task immediately in the default OF document.
 * @method OFparse
 * @param {string} string - String to parse as task
 * @return {object} Omnifocus task object
 * @example
 * OFparse('Do Something! @work ::misc project #4pm #tomorrow //Note')
 * First # is deferred date, 2nd # is due date. If only one specified it is used as due date
 */
function OFparse(string) {
	return OF.parseTasksInto(OFdoc, {withTransportText: string});
}