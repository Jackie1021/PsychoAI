#!/usr/bin/env node
/**
 * Test Gemini API connection and response
 */

const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

const apiKey = process.env.GEMINI_API_KEY;

console.log('🧪 Testing Gemini API...\n');
console.log('API Key:', apiKey ? `${apiKey.substring(0, 10)}...` : 'NOT FOUND');

if (!apiKey) {
  console.error('❌ GEMINI_API_KEY not found in .env file');
  process.exit(1);
}

const genAI = new GoogleGenerativeAI(apiKey);
const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

const testPrompt = `You are a matchmaker analyzing compatibility between two users.

User A Traits: storyteller, observer, sound hunt
User A Bio: "No description provided"

User B Traits: world builder, sketches, storyteller, sound hunt
User B Bio: "Building imaginary worlds through art and sound."

Respond with a JSON object containing:
1. summary: A witty one-liner about their compatibility (under 15 words)
2. totalScore: A compatibility score from 0-100
3. similarFeatures: An object with 3-4 areas of similarity, each with score and explanation

Return ONLY valid JSON, no other text.`;

async function test() {
  try {
    console.log('\n📤 Sending request to Gemini API...\n');
    
    const result = await model.generateContent(testPrompt);
    const response = await result.response;
    const text = response.text();
    
    console.log('✅ API Response received!\n');
    console.log('📄 Raw response:');
    console.log('─'.repeat(60));
    console.log(text);
    console.log('─'.repeat(60));
    
    // Try to parse JSON
    console.log('\n🔍 Attempting to parse JSON...\n');
    
    const jsonText = text.match(/```json([\s\S]*?)```/)?.[1] ?? text;
    const parsed = JSON.parse(jsonText);
    
    console.log('✅ Successfully parsed JSON:');
    console.log(JSON.stringify(parsed, null, 2));
    
    // Validate structure
    console.log('\n✅ Validation:');
    console.log('  - summary:', parsed.summary ? '✓' : '✗');
    console.log('  - totalScore:', parsed.totalScore !== undefined ? '✓' : '✗');
    console.log('  - similarFeatures:', parsed.similarFeatures ? '✓' : '✗');
    
    if (parsed.similarFeatures) {
      const keys = Object.keys(parsed.similarFeatures);
      console.log(`  - Features count: ${keys.length}`);
      keys.forEach(key => {
        const feature = parsed.similarFeatures[key];
        console.log(`    - ${key}: score=${feature.score}, explanation=${feature.explanation ? '✓' : '✗'}`);
      });
    }
    
    console.log('\n🎉 Test PASSED! API is working correctly.\n');
    
  } catch (error) {
    console.error('\n❌ Test FAILED!\n');
    console.error('Error type:', error.constructor.name);
    console.error('Error message:', error.message);
    
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
    
    if (error.stack) {
      console.error('\nStack trace:');
      console.error(error.stack);
    }
    
    process.exit(1);
  }
}

test();
