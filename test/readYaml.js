
const yaml = require('js-yaml');
const fs = require('fs');


const readYaml = (path) => {
    let fileContents = fs.readFileSync(path, 'utf8');
    let data = yaml.load(fileContents);
    return data
}

module.exports = readYaml;


