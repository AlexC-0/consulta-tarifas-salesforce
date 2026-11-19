const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
module.exports = { ...jestConfig, testPathIgnorePatterns: ['<rootDir>/.local/','<rootDir>/node_modules/'] };
