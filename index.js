#!/usr/bin/env node
/* eslint-disable func-names */
/* eslint-disable no-param-reassign */
import printMessage from 'print-message';
import inquirer from 'inquirer';
import { devices } from 'playwright';
import {
  getVersion,
  cleanUp,
  setHeadlessMode,
  getUserDataTxt,
  writeToUserDataTxt,
  getStoragePath,
} from './utils.js';
import { prepareData, messageOptions, getPlaywrightDeviceDetailsObject, getBrowserToRun, getScreenToScan, getClonedProfilesWithRandomToken, deleteClonedProfiles } from './constants/common.js';
import questions from './constants/questions.js';
import combineRun from './combine.js';
import playwrightAxeGenerator from './playwrightAxeGenerator.js';
import constants from './constants/constants.js';

const userData = getUserDataTxt();

if (userData) {
  printMessage(
    [
      `Purple HATS (ver ${getVersion()})`,
      'We recommend using Chrome browser for the best experience.',
      '',
      `Welcome back ${userData.name}!`,
      `(Refer to readme.txt on how to change your profile)`,
    ],
    {
      // Note that the color is based on kleur NPM package
      border: true,
      borderColor: 'magenta',
    },
  ); 

  inquirer.prompt(questions).then(async answers => {
    await runScan(answers);
  });
} else {
  printMessage(
    [
      `Purple HATS (ver ${getVersion()})`,
      'We recommend using Chrome browser for the best experience.',
    ],
    {
      // Note that the color is based on kleur NPM package
      border: true,
      borderColor: 'magenta',
    },
  );

  printMessage(
    [
      `To personalise your experience, we will be collecting your name, email address and app usage data.`,
      `Your information fully complies with GovTech's Privacy Policy.`,
    ],
    {
      border: false,
    },
  );

  inquirer.prompt(questions).then(async answers => {
    const { name, email } = answers;

    await writeToUserDataTxt('name', name);
    await writeToUserDataTxt('email', email);

    await runScan(answers); 
  });
}

const runScan = async (answers) => {
  const screenToScan = getScreenToScan(answers.deviceChosen, answers.customDevice, answers.viewportWidth);
  answers.playwrightDeviceDetailsObject = getPlaywrightDeviceDetailsObject(answers.deviceChosen, answers.customDevice, answers.viewportWidth);
  let { browserToRun, clonedDataDir } = getBrowserToRun(constants.browserTypes.chrome);
  deleteClonedProfiles(browserToRun);
  answers.browserToRun = browserToRun; 
  answers.nameEmail = `${userData.name}:${userData.email}`;
  answers.fileTypes = 'html-only';
  
  const data = prepareData(answers);
  clonedDataDir = getClonedProfilesWithRandomToken(data.browser, data.randomToken); 
  data.userDataDirectory = clonedDataDir; 

  setHeadlessMode(data.browser, data.isHeadless); 
  printMessage(['Scanning website...'], messageOptions);

  if (answers.scanner === constants.scannerTypes.custom) {
    await playwrightAxeGenerator(data);
  } else {
    await combineRun(data, screenToScan);
  }

  // Delete cloned directory 
  deleteClonedProfiles(data.browser);

  // Delete dataset and request queues
  cleanUp(data.randomToken);

  const storagePath = getStoragePath(data.randomToken);
  const messageToDisplay = [
    `Report of this run is at ${constants.cliZipFileName}`,
    `Results directory is at ${storagePath}`,
  ];
  printMessage(messageToDisplay);
  process.exit(0);
}