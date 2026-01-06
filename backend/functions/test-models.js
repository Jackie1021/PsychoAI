#!/usr/bin/env node
const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

const apiKey = process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(apiKey);

const modelsToTry = [
  'gemini-1.5-flash',
  'gemini-1.5-pro',
  'gemini-1.0-pro',
  'gemini-2.5-flash',
  'models/gemini-1.5-flash',
  'models/gemini-1.5-pro',
];

async function testModel(modelName) {
  try {
    console.log(`\n🧪 Testing: ${modelName}`);
    const model = genAI.getGenerativeModel({ model: modelName });
    const result = await model.generateContent('Say "Hello World" in JSON format');
    const response = await result.response;
    console.log(`✅ ${modelName} works!`);
    console.log(`   Response: ${response.text().substring(0, 100)}...`);
    return true;
  } catch (error) {
    console.log(`❌ ${modelName} failed: ${error.message.substring(0, 80)}...`);
    return false;
  }
}

async function findWorkingModel() {
  console.log('🔍 Testing Gemini models to find one that works...');
  
  for (const modelName of modelsToTry) {
    const works = await testModel(modelName);
    if (works) {
      console.log(`\n✨ Use this model: ${modelName}`);
      break;
    }
  }
}

findWorkingModel();
